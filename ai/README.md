# Education History AI Assistant

A deliberately small, bare-bones proof of concept: a question-answering
assistant over the text of *The Development of the Theory and Practice of
Education in New Brunswick 1784–1900*. It exists to learn how the pieces of a
practical AI feature fit together, not to be a product. Every dependency is
local — no external AI provider is called, and no site content leaves the
machine.

## The idea: retrieval-augmented generation

A language model small enough to run on a laptop knows nothing about this
book, and asking it directly produces confident fiction. So we do not ask it
to recall anything. We look up the relevant passages ourselves and hand them
over with the question attached. The model's only job is to phrase an answer
from text we chose.

That splits the problem into two halves, and each half fails in its own way:

1. **Retrieval** — given a question, find the passages that address it.
   Failure here means the model answers from irrelevant text.
2. **Generation** — given those passages, write the answer. Failure here means
   the model contradicts or embellishes text it was handed.

Keeping them separate is the whole point of the design: when an answer is
wrong, you can tell which half broke by looking at what retrieval returned.

## How the parts connect

```
Drupal nodes                                          Drupal question form
     │                                                        │
     │ GET /api/book-pages                                    │ POST /ask
     ▼                                                        ▼
BookPagesController ──► indexing.py ──► Postgres ◄── retrieval.py ──► llm.py
   (JSON: title,        chunk +         + pgvector    top 5 nearest    Ollama
    url, body)          embed           (book_chunks)    chunks        answers
```

The Drupal module (`custom/modules/eduhistory_ai`) is both ends of the flow —
it publishes the text and it asks the questions. The FastAPI service (`ai/`)
is the middle.

### Indexing, one file at a time

| File | Responsibility |
| --- | --- |
| `app/drupal_client.py` | Fetches `/api/book-pages`. Drupal owns the content; this service never touches Drupal's database. |
| `app/indexing.py` | Splits each printed page into overlapping 800-character chunks, on word boundaries. |
| `app/embeddings.py` | Turns text into 384-number vectors, via Ollama. The only place embeddings are produced. |
| `app/models.py` | The `book_chunks` table: the chunk text, where it came from, and its vector. |
| `app/retrieval.py` | Embeds the question, then asks Postgres for the nearest stored vectors. |
| `app/llm.py` | Builds the prompt — instructions, retrieved context, question — and sends it to Ollama. |
| `app/main.py` | The three HTTP endpoints: `/health`, `/index`, `/ask`. |

Three ideas in that table carry most of the weight.

**Why chunk at all, and why 800 characters.** A whole chapter is too coarse to
retrieve usefully: a match on one sentence drags in thousands of irrelevant
words, crowding the model's limited context. But the upper bound is not a
matter of taste — `all-MiniLM-L6-v2` reads at most **256 word-pieces** and
silently ignores the rest. Sampled against this book's prose, 1200 characters
came to 260–280 tokens, so an oversized chunk would be stored and shown to the
model while its tail stayed invisible to search. 800 characters lands near 200
tokens, inside the limit. The 200 characters of overlap between consecutive
chunks exist so a sentence straddling a boundary still appears whole in at
least one of them.

**Why vectors.** Keyword search fails when the question and the text use
different words for the same thing — "who paid for schools" versus "assessment
and public funding." An embedding model maps text to coordinates where related
passages land near each other regardless of vocabulary, so "nearest" becomes a
usable proxy for "most relevant." That is all the `<=>` operator in
`retrieval.py` computes: cosine distance between the question's vector and
each stored chunk's.

**Why one embedding module.** The same model must embed both the documents and
the questions — vectors from two different models describe different coordinate
spaces, and comparing across them produces nonsense rather than an error.
`embeddings.py` exists so both callers physically cannot drift apart.

**Why Ollama does the embedding.** It is already running to write the answers,
and `all-minilm` in its library *is* `all-MiniLM-L6-v2` — same 384 dimensions,
same model. Reusing it means this container needs no machine-learning runtime
of its own. Dropping `torch` and `sentence-transformers` took site-packages
from 1.4GB to 171MB; dropping the compiler they didn't need saved another
350MB. The image went from roughly **1.9GB to ~310MB**, and the second copy of
the model that used to sit in memory stopped existing.

### Citing a page, not a chapter

The book lives in 21 Drupal nodes, one per chapter, and Chapter 8 alone runs to
148,000 characters. Citing the node meant answering "see Chapter 8" — forty
printed pages — which for a history assistant is barely a citation at all.

The fix was already in the source data. The digitisation preserved the 1947
edition's pagination as markers in the body field:

```html
<div class="pagenum"><a href="/..../MacN1947.pdf#page=53" id="p35">35</a></div>
```

Each one gives the printed page number, an anchor into the web text, and a deep
link to that page of the scanned original. `BookPagesController` used to erase
all of it with `strip_tags()`. It now splits on those markers and publishes the
book as **284 segments, 279 of them carrying a printed page number** — matching
the pagination of the physical book. Chunking then happens *within* a page and
never across two, so every chunk can name exactly one page.

The result is a source list of "Chapter 8, p. 167", linking both to
`/MacNcha8#p167` and to page 185 of the scan — and the model cites pages in its
prose, because the excerpts are labelled that way in the prompt.

Two costs worth naming. A sentence spanning a page break is now split between
two chunks, since chunks no longer cross page boundaries. And `models.py` grew
three columns, which in a service with no migrations means the table has to be
dropped and rebuilt:

```sh
docker compose exec ai-postgres-lib-unb-ca psql -U eduhist_ai -d eduhist_ai \
  -c 'DROP TABLE IF EXISTS book_chunks;'
docker compose restart ai-api      # startup recreates it from models.py
curl -X POST http://localhost:5084/index
```

### What the first real run taught us

Indexed against the actual book — 21 nodes, 912,000 characters, 1,532 chunks —
most questions needing more than a single sentence came back as *"I could not
find that."* Retrieval was not the problem. Asked how teacher training changed
over the century, the search returned passages on the Central Training School,
the Act of 1852, and rising numbers of trained teachers, at good distances.
The model was handed the right material and declined it.

The cause was one clause in the prompt. `If the answer is not contained in the
context` reads, to a 3B model, as *not stated in a single sentence* — so any
question requiring two excerpts to be combined was refused on principle. The
model said as much: the excerpts "do not provide a comprehensive overview."

Worth recording because the instinct is to reach for retrieval knobs:

| Change | Result |
| --- | --- |
| More chunks (5 → 12) under the strict prompt | still refused |
| Stitching neighbouring chunks together for coherence | no improvement |
| Both at once (~30,000 characters of context) | **worse** — refused again |
| Softening one clause in the prompt, same 5 chunks | **answered well** |

Two lessons. The prompt was doing more damage than any retrieval setting. And
context is not free: the 30,000-character attempt performed worse than the
4,800-character one, because a small model degrades when its window fills, so
"send more" is a real trade rather than a safe default.

Loosening a grounding rule invites invention, so the out-of-scope questions
were re-run afterwards. Both still refuse.

## The local stack

Three containers were added to `docker-compose.yml` for this, alongside the
existing Drupal, MariaDB, Redis and Solr services:

- **`ai-api`** — this FastAPI service. Reachable at `http://localhost:5084`
  from your machine, and at `http://ai-api:8000` from Drupal (that hostname is
  hardcoded in `EducationHistoryQaForm`, which is why the service carries that
  name). `app/` is bind-mounted and uvicorn runs with `--reload`, so editing a
  Python file restarts the service without a rebuild.
- **`ai-postgres-lib-unb-ca`** — Postgres with pgvector. A *second* database:
  Drupal stays on MariaDB, which has no vector type. Nothing in Drupal reads
  this database and nothing here reads Drupal's.
- **`ai-ollama-lib-unb-ca`** — runs both models: `all-minilm` to embed and
  `llama3.2:3b` to answer.

Configuration lives in `env/ai.env` and `env/ai-postgres.env`, following the
existing per-service `env/` convention. The Python code reads every hostname
from the environment and never hardcodes one.

## Running it

From the repository root, with the stack already deployed
(`vendor/bin/dockworker deploy`):

```sh
# 1. Build and start the three new services.
docker compose up -d --build ai-api ai-postgres-lib-unb-ca ai-ollama-lib-unb-ca

# 2. Download the model weights. These are not in any image; they land in the
#    ollama-data volume and persist. About 2GB and 46MB respectively.
docker compose exec ai-ollama-lib-unb-ca ollama pull llama3.2:3b
docker compose exec ai-ollama-lib-unb-ca ollama pull all-minilm

# 3. Confirm the API is up.
curl http://localhost:5084/health

# 4. Read the book out of Drupal, chunk it, embed it, store it. A minute or
#    two; `docker compose logs -f ai-api` shows batch-by-batch progress.
curl -X POST http://localhost:5084/index

# 5. Ask something.
curl -X POST http://localhost:5084/ask \
  -H 'Content-Type: application/json' \
  -d '{"question": "How were schools funded in early New Brunswick?"}'
```

Then visit `/education-history-qa` on the site for the same thing with a form
around it.

Step 4 is not automatic and needs re-running whenever the book content
changes — `/index` deletes every row and rebuilds from scratch. For a corpus
that changes once a decade, that is the right amount of machinery.

### When something breaks

The pipeline is worth debugging in stages rather than end to end, because each
stage is separately observable:

```sh
# Is Drupal actually publishing text? (Should be a JSON array with bodies.)
docker compose exec ai-api curl -s http://educationhistory-lib-unb-ca/api/book-pages | head -c 500

# Did anything get stored?
docker compose exec ai-postgres-lib-unb-ca psql -U eduhist_ai -d eduhist_ai \
  -c 'SELECT count(*), count(DISTINCT node_id), count(DISTINCT printed_page) FROM book_chunks;'

# Is the model present?
docker compose exec ai-ollama-lib-unb-ca ollama list

docker compose logs -f ai-api
```

An answer of "I could not find that in the education history excerpts
provided" is the retrieval half reporting that it found nothing useful — check
the `sources` array in the response, not the prompt.

## This service is local-only. The Drupal module is not.

Worth stating plainly, because the two halves of this feature deploy by
different mechanisms and only one of them reaches a server.

**The AI service never leaves your machine.** CI builds a single image from the
root `Dockerfile` and rolls out a single Kubernetes deployment:

```yaml
# .github/workflows/deployment-workflow.yaml
image-name: 'ghcr.io/unb-libraries/educationhistory.lib.unb.ca'
k8s-deployment-name: 'educationhistory-lib-unb-ca'
```

`docker-compose.yml` is never read by CI — it is local development tooling, and
it is the only place `ai-api`, Postgres+pgvector and Ollama are defined. The
root `.dockerignore` ignores everything but `Dockerfile`, `custom`, `build` and
`configuration`, so `ai/` cannot even enter the build context. Nothing on the
cluster would answer on `ai-api:8000`.

**The Drupal module does deploy**, because the image copies `./custom/modules`
and `./configuration`. So if `eduhistory_ai` is listed in
`configuration/core.extension.yml` when a branch reaches `dev` or `prod`, the
module is enabled on a server where its backend does not exist:

- `/education-history-qa` becomes publicly reachable and fails on every
  question.
- `/api/book-pages` publicly serves ~960KB of uncached JSON per request.

**This is why the work stays on the `pilot` branch.** `eduhistory_ai: 0` is
present in `core.extension.yml` so local deploys enable the module
automatically, which is exactly what makes merging to `dev` unsafe. Before any
such merge, either remove that line so the code ships dormant and is enabled
per environment with drush, or finish deploying the service properly.

Doing that properly means: publishing `ai/` as its own image, adding
deployments for it plus Postgres and Ollama, making the service URL in
`EducationHistoryQaForm` configurable so the form can hide itself when unset,
authenticating `/index`, and budgeting cluster memory for a model that
`keep_alive` deliberately holds resident. `trusted_host_patterns` in
`build/settings/settings.dev.inc` would also reject the container-name Host
header the indexer relies on locally.

## Deliberately not done yet

Named here so the gaps read as decisions rather than oversights:

- **`/index` has no authentication.** Tolerable on a private compose network,
  not beyond it. See the deployment note above.
- **No vector index.** `book_chunks` has no `ivfflat` or `hnsw` index, so every
  question scans every row. The measured corpus is ~1500 chunks and ~2MB of
  vectors, where a full scan takes well under a millisecond. An index would
  start paying for itself a couple of orders of magnitude further up.
- **Short factual lookups can miss.** "When was King's College founded?" fails
  even though 44 chunks mention the college: the top five come back at
  distances of 0.40–0.54 with no founding passage among them. Dense retrieval
  is weakest exactly where keyword search is strongest — a specific name
  attached to a specific date. Hybrid search, running Postgres full-text
  alongside the vector query and merging, is the usual answer.
- **Structural questions have nothing to match.** "What does Chapter 3 cover?"
  or "how many chapters are there?" cannot be answered from any single
  excerpt, because the book's shape is not in the chunks. This needs a
  different mechanism, not better retrieval.
- **Footnote numbers are inlined.** Stripping tags flattens footnote markers
  into the prose, leaving bare digits mid-sentence in both the embeddings and
  any quoted answer.
- **No conversation.** Each question is answered independently; there is no
  history, so follow-ups like "what about after 1850?" have no antecedent.
- **`llama3.2:3b` is the ceiling, not the retrieval.** It handles extractive
  questions well and struggles to synthesize across chapters. A 7–8B model
  answers those noticeably better and runs roughly three times slower on CPU,
  which starts to press against the Drupal form's 120-second timeout.
- **Answer quality is unmeasured.** There is no set of questions with known
  answers, so "is this better?" is currently a matter of opinion. Setting
  `temperature` to 0 at least makes answers repeatable, which is a precondition
  for comparing anything.
