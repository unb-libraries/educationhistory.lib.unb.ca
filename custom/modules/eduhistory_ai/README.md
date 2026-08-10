# eduhistory_ai

The Drupal half of the education history AI assistant. It does two things, and
they sit at opposite ends of the same pipeline:

1. **Publishes the book** as JSON at `/api/book-pages`, so it can be indexed.
2. **Asks questions of it** through a form at `/education-history-qa`.

Everything between those two points — chunking, embeddings, vector search, the
language model — lives in the FastAPI service in [`ai/`](../../../ai/), which
has its own walkthrough in [`ai/README.md`](../../../ai/README.md). This
document covers the Drupal side only, file by file.

```
        ┌─────────────────── this module ───────────────────┐
        │                                                   │
   BookPagesController                        EducationHistoryQaForm
   GET /api/book-pages                        POST /education-history-qa
        │                                                   │
        │ the book, split by printed page          question │  ▲ answer
        ▼                                                   ▼  │ + sources
   ┌────────────────────── ai-api (FastAPI) ──────────────────────┐
   │  index: chunk → embed → store        ask: search → generate  │
   └──────────────────────────────────────────────────────────────┘
```

Note the direction of the arrows. Drupal is never called *by* the AI service
during a question; it is read once at indexing time. And Drupal calls the AI
service only when someone submits the form. Neither can bring down the other:
if `ai-api` is stopped, the rest of the site is unaffected and the form shows
an error.

---

## `eduhistory_ai.info.yml`

```yaml
name: Education History AI
type: module
core_version_requirement: ^11
dependencies:
  - drupal:node
  - drupal:text
```

`node` and `text` are the real dependencies: the controller reads nodes and
their `body` fields. Nothing here depends on the AI service being installed or
reachable — the module is inert but harmless without it.

**Operational note.** The module is enabled through
`configuration/core.extension.yml`. Restoring a production database snapshot
overwrites that, because production does not have this module enabled yet, so
the routes vanish and `/api/book-pages` starts returning 404. After any
snapshot restore:

```sh
vendor/bin/dockworker drush en eduhistory_ai -y
```

---

## `eduhistory_ai.routing.yml`

Two routes, both requiring only `access content` — the permission anonymous
users already have for reading the book.

```yaml
eduhistory_ai.book_pages:
  path: '/api/book-pages'
  defaults:
    _controller: '\Drupal\eduhistory_ai\Controller\BookPagesController::content'
  requirements:
    _permission: 'access content'

eduhistory_ai.qa_form:
  path: '/education-history-qa'
  defaults:
    _form: '\Drupal\eduhistory_ai\Form\EducationHistoryQaForm'
  requirements:
    _permission: 'access content'
```

`_controller` returns a response directly; `_form` hands Drupal a form class
and lets it manage the build/validate/submit cycle. That is the whole
difference between the two declarations.

`access content` is the right permission in the sense that `/api/book-pages`
exposes nothing that isn't already public — it is the same text, minus the
theme. It is worth being deliberate about that rather than incidental: the
endpoint is a machine-readable copy of the entire book at one URL.

---

## `src/Controller/BookPagesController.php`

The more interesting of the two files. Its job is to hand over the book in a
form that can be cited precisely.

### The problem it solves

The book is 21 nodes — one per chapter. Chapter 8 alone is 148,000 characters.
If the smallest thing the indexer knows about is a node, then the best possible
citation is "see Chapter 8", which is forty printed pages. For a history
assistant, where the point is that a claim can be checked, that is not a
citation.

The digitisation preserved the 1947 edition's pagination in the body markup:

```html
<div class="pagenum"><a href="/..../MacN1947.pdf#page=53" id="p35">35</a></div>
```

Three useful things in one element: the printed page number (`35`), an anchor
for linking into the web text (`#p35`), and a deep link to that page of the
scanned original. The controller's real work is *not throwing this away*.

### Selecting the nodes

```php
$nids = \Drupal::entityQuery('node')
  ->accessCheck(TRUE)
  ->condition('status', 1)
  ->condition('type', ['page', 'book'], 'IN')
  ->sort('nid', 'ASC')
  ->execute();
```

`accessCheck(TRUE)` means the query respects node access, so an unpublished or
restricted node cannot leak into the index. Filtering `type` in the query
matters: an earlier version loaded every published node and discarded the wrong
bundles in PHP afterwards, which fully hydrates entities only to throw them
away.

### Splitting on page markers

`splitIntoPrintedPages()` does the segmentation with one regular expression and
`PREG_SPLIT_DELIM_CAPTURE`:

```php
private const PAGE_MARKER_PATTERN =
  '#<div\s+class="pagenum">\s*<a\s+href="([^"]*)"\s+id="([^"]*)"\s*>(.*?)</a>\s*</div>#is';

$parts = preg_split(self::PAGE_MARKER_PATTERN, $body, -1, PREG_SPLIT_DELIM_CAPTURE);
```

`DELIM_CAPTURE` keeps the captured groups in the output array, so `$parts`
alternates predictably:

```
[ text before first marker, href, anchor, label, text, href, anchor, label, text, … ]
```

The first element is shifted off and, if non-empty, emitted with a `NULL` page
number — front matter that precedes the first marker is kept rather than
silently dropped. The rest is consumed with `array_chunk($parts, 4)`, one group
per printed page.

Nodes with no markers at all — the table of contents, the title page — still
produce a single unpaginated segment, so nothing is lost by being unnumbered.

### Turning markup into text

```php
$text = preg_replace('/<[^>]+>/', ' ', $markup);
$text = html_entity_decode($text, ENT_QUOTES | ENT_HTML5);
$text = preg_replace('/\s+/', ' ', $text);
```

The space in the replacement is deliberate. `strip_tags()` removes tags without
leaving anything behind, so `<p>word</p><p>next</p>` becomes `wordnext` — two
words fused into one that exists in no dictionary and matches nothing. Since
this text is about to be embedded, that is a silent corruption. Replacing each
tag with a space and then collapsing runs of whitespace avoids it.

### What it returns

```json
[
  {
    "id": 4,
    "title": "Chapter 4",
    "url": "/MacNcha4",
    "type": "book",
    "book_parent": null,
    "weight": 0,
    "pages": [
      {
        "page": "35",
        "url": "/MacNcha4#p35",
        "scan_url": "/sites/default/files/images/MacN1947.pdf#page=53",
        "text": "CHAPTER 4 THE LOYALIST PATTERN It is customary to think of…"
      }
    ]
  }
]
```

`book_parent` and `weight` come from the Book module's hierarchy. They are
published because they were cheap to include, but nothing downstream reads
them yet — the indexer currently ignores the book's structure entirely.

Against the real book this is **21 nodes, 284 segments, 279 of them carrying a
printed page number** — matching the pagination of the physical volume.

Check it directly:

```sh
curl -s http://localhost:3084/api/book-pages | python3 -m json.tool | head -40
```

---

## `src/Form/EducationHistoryQaForm.php`

A standard `FormBase`. The only unusual thing it does is call another service
and render the reply.

### `buildForm()`

Builds the textarea and submit button, then conditionally appends two more
sections if a previous submission left an answer behind:

```php
$answer  = $form_state->get('answer');
$sources = $form_state->get('sources');
```

Note `get()`/`set()`, not `getValue()`. `$form_state->set()` stores arbitrary
data that survives a rebuild, whereas `getValue()` reads submitted input. The
answer is not user input, so it belongs in storage.

### `submitForm()`

```php
$response = \Drupal::httpClient()->post('http://ai-api:8000/ask', [
  'json' => ['question' => $question],
  'timeout' => 120,
]);

$data = json_decode((string) $response->getBody(), TRUE);

$form_state->set('answer', $data['answer'] ?? 'No answer returned.');
$form_state->set('sources', $data['sources'] ?? []);
$form_state->setRebuild(TRUE);
```

Four things worth noticing:

- **`ai-api` is a Docker service name**, resolved on the compose network. This
  is why the service in `docker-compose.yml` must be called exactly that.
- **`setRebuild(TRUE)`** re-renders the form in the same request instead of
  redirecting, which is what lets the answer appear beneath the question.
- **The 120-second timeout** is generous because the language model runs on
  CPU. `num_predict` in the service's `llm.py` caps the answer length partly to
  stay clear of this ceiling.
- **Two catch blocks.** `RequestException` means the AI service is unreachable
  and gets a plain message; anything else surfaces its own text. Either way the
  page renders — a stopped `ai-api` degrades this form, not the site.

### Rendering the sources

Each source arrives as:

```json
{ "title": "Chapter 8", "printed_page": "167",
  "url": "/MacNcha8#p167",
  "scan_url": "/sites/default/files/images/MacN1947.pdf#page=185",
  "chunk_index": 64 }
```

Retrieval returns five excerpts and several often come from the same page, so
the loop deduplicates on `url` before rendering. Each entry becomes a link to
the passage in the web text, plus a second link into the scanned original at
the same page:

> Chapter 8, p. 167 · scan

That pairing is the point of the whole page-aware exercise: a reader can jump
to the passage, and then check it against the printed 1947 book.

---

## What happens when someone asks a question

1. Form submits to `submitForm()`.
2. Guzzle POSTs `{"question": "…"}` to `http://ai-api:8000/ask`.
3. The service embeds the question, finds the five nearest chunks in Postgres,
   and asks the local model to answer from them.
4. It replies with `answer` and `sources`.
5. `setRebuild(TRUE)` re-renders the form with both sections appended.

Typical wall time is 10–20 seconds, nearly all of it step 3. There is no
conversation history: each question is answered on its own, so follow-ups like
"what about after 1850?" have no antecedent.

---

## Rough edges

Named so they read as known rather than overlooked:

- **The service URL is hardcoded** in `submitForm()`. It belongs in
  configuration or a setting, like every URL on the service side already is.
- **Output is built as HTML strings** and passed through `#markup`. It works —
  `#markup` runs through `Xss::filterAdmin()`, which permits `<a>` and `<ul>` —
  but the idiomatic form is a render array, `#theme => 'item_list'` with
  `#url`/`Link` objects, which would remove the manual `htmlspecialchars()`
  calls entirely.
- **`/api/book-pages` sets no cache metadata.** Every request rebuilds the
  whole ~960KB response from scratch. Indexing happens rarely enough that this
  has not mattered, but the response carries no cache tags, so it would also
  not know to invalidate when a node changes.
- **No pager on the JSON endpoint.** It loads all 21 nodes at once. Fine for
  this book; not a pattern to copy for a large corpus.
- **The form has no throttling.** Each submission occupies the language model
  for many seconds, and nothing prevents repeated submissions.
