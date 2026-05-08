<?php

namespace Drupal\eduhistory_ai\Controller;

use Drupal\Core\Controller\ControllerBase;
use Symfony\Component\HttpFoundation\JsonResponse;
use Drupal\node\Entity\Node;

class BookPagesController extends ControllerBase {

  public function content(): JsonResponse {
    $query = \Drupal::entityQuery('node')
      ->accessCheck(TRUE)
      ->condition('status', 1)
      ->sort('nid', 'ASC');

    $nids = $query->execute();
    $nodes = Node::loadMultiple($nids);

    $items = [];

    foreach ($nodes as $node) {
      if ($node->bundle() !== 'page' && $node->bundle() !== 'book') {
        continue;
      }

      $body = '';

      if ($node->hasField('body') && !$node->get('body')->isEmpty()) {
        $body = $node->get('body')->value;
        $body = html_entity_decode(strip_tags($body));
        $body = preg_replace('/\s+/', ' ', $body);
        $body = trim($body);
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

      $items[] = [
        'id' => (int) $node->id(),
        'title' => $node->getTitle(),
        'url' => $node->toUrl()->toString(),
        'type' => $node->bundle(),
        'book_parent' => $book_parent,
        'weight' => $book_weight,
        'body' => $body,
      ];
    }

    return new JsonResponse($items);
  }

}