<?php

namespace Drupal\eduhistory_ai\Controller;

use Drupal\Core\Controller\ControllerBase;
use Symfony\Component\HttpFoundation\JsonResponse;
use Drupal\node\Entity\Node;

/**
 * Publishes the book's text for the AI service to index.
 *
 * The text is emitted one printed page at a time rather than one node at a
 * time. The digitised book carries the 1947 edition's pagination as markers in
 * the body field:
 *
 * @code
 * <div class="pagenum"><a href="/..../MacN1947.pdf#page=53" id="p35">35</a></div>
 * @endcode
 *
 * Each marker gives the printed page number, an in-page anchor, and a deep
 * link to that page of the scanned original. Splitting on them means an
 * answer can cite "Chapter 4, p. 35" and link to the exact passage, instead of
 * pointing at a chapter that may run to forty pages.
 */
class BookPagesController extends ControllerBase {

  /**
   * Matches one printed-page marker, capturing its PDF link, anchor and label.
   */
  private const PAGE_MARKER_PATTERN = '#<div\s+class="pagenum">\s*<a\s+href="([^"]*)"\s+id="([^"]*)"\s*>(.*?)</a>\s*</div>#is';

  public function content(): JsonResponse {
    // Filter by bundle in the query rather than loading every published node
    // and discarding most of them in PHP.
    $nids = \Drupal::entityQuery('node')
      ->accessCheck(TRUE)
      ->condition('status', 1)
      ->condition('type', ['page', 'book'], 'IN')
      ->sort('nid', 'ASC')
      ->execute();

    $items = [];

    foreach (Node::loadMultiple($nids) as $node) {
      $body = '';

      if ($node->hasField('body') && !$node->get('body')->isEmpty()) {
        $body = (string) $node->get('body')->value;
      }

      $book_parent = NULL;
      $book_weight = 0;

      if ($node->hasField('book') && !$node->get('book')->isEmpty()) {
        $book_value = $node->get('book')->first()?->getValue();
        if ($book_value) {
          $book_parent = $book_value['pid'] ?? NULL;
          $book_weight = $book_value['weight'] ?? 0;
        }
      }

      $url = $node->toUrl()->toString();
      $pages = $this->splitIntoPrintedPages($body, $url);

      if (!$pages) {
        continue;
      }

      $items[] = [
        'id' => (int) $node->id(),
        'title' => $node->getTitle(),
        'url' => $url,
        'type' => $node->bundle(),
        'book_parent' => $book_parent,
        'weight' => $book_weight,
        'pages' => $pages,
      ];
    }

    return new JsonResponse($items);
  }

  /**
   * Splits body markup into segments, one per printed page of the 1947 edition.
   *
   * @param string $body
   *   The raw body markup.
   * @param string $node_url
   *   The node's path, used to build anchored links back into the web text.
   *
   * @return array
   *   Segments, each with its printed page number, anchored URL, link to the
   *   scan, and plain text. Front matter appearing before the first marker is
   *   returned with a NULL page number rather than discarded, and nodes with
   *   no markers at all yield a single unpaginated segment.
   */
  private function splitIntoPrintedPages(string $body, string $node_url): array {
    // PREG_SPLIT_DELIM_CAPTURE keeps the captured groups, so the result reads
    // as: [text before first marker, href, anchor, label, text, href, ...].
    $parts = preg_split(
      self::PAGE_MARKER_PATTERN,
      $body,
      -1,
      PREG_SPLIT_DELIM_CAPTURE
    );

    if ($parts === FALSE) {
      return [];
    }

    $pages = [];

    // Anything before the first marker belongs to no printed page.
    $preamble = $this->toPlainText(array_shift($parts));
    if ($preamble !== '') {
      $pages[] = [
        'page' => NULL,
        'url' => $node_url,
        'scan_url' => NULL,
        'text' => $preamble,
      ];
    }

    // Then consume the remainder in groups of four.
    foreach (array_chunk($parts, 4) as $chunk) {
      [$scan_url, $anchor, $label, $text] = $chunk + [NULL, NULL, NULL, ''];

      $text = $this->toPlainText((string) $text);
      if ($text === '') {
        continue;
      }

      $page = trim($this->toPlainText((string) $label));

      $pages[] = [
        'page' => $page !== '' ? $page : NULL,
        'url' => $anchor ? $node_url . '#' . $anchor : $node_url,
        'scan_url' => $scan_url ?: NULL,
        'text' => $text,
      ];
    }

    return $pages;
  }

  /**
   * Reduces markup to normalized plain text.
   */
  private function toPlainText(string $markup): string {
    // Insert a space where tags are removed, so that markup acting as a word
    // boundary does not silently fuse two words together.
    $text = preg_replace('/<[^>]+>/', ' ', $markup);
    $text = html_entity_decode($text, ENT_QUOTES | ENT_HTML5);

    // Decoding turns &nbsp; into U+00A0, which PCRE's \s does not match
    // without the /u modifier. Left alone it survives the collapse below and
    // leads the text of every printed page, so it is folded to a plain space
    // first rather than risking /u on markup of unverified encoding.
    $text = str_replace("\xC2\xA0", ' ', $text);
    $text = preg_replace('/\s+/', ' ', $text);

    return trim($text);
  }

}
