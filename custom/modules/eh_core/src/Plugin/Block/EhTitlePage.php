<?php

namespace Drupal\eh_core\Plugin\Block;

use Drupal\Core\Block\BlockBase;

/**
 * Provides an ISSUU banner block for the home page.
 *
 * @Block(
 *   id = "eh_link_title_page",
 *   admin_label = @Translation("EH Link to Title Page"),
 *   category = @Translation("Misc"),
 * )
 */
class EhTitlePage extends BlockBase {

  /**
   * {@inheritdoc}
   */
  public function build() {
    $text = '
      <ul class="book-pager">
        <li class="book-pager__item book-pager__item--next">
          <a href="/MacNtit" rel="next" title="Go to next page">
            Title Page <b>›</b>
          </a>
        </li>
      </ul>
    ';

    return [
      '#markup' => $this->t($text),
    ];
  }

}
