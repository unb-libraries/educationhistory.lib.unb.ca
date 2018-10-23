<?php

namespace Drupal\eh_core\Plugin\Block;

use Drupal\Core\Block\BlockBase;

/**
 * Provides an ISSUU banner block for the home page.
 *
 * @Block(
 *   id = "eh_title",
 *   admin_label = @Translation("EH Title"),
 *   category = @Translation("Misc"),
 * )
 */
class EhTitle extends BlockBase {

  /**
   * {@inheritdoc}
   */
  public function build() {
    $text = '
      <h2 style="font-size:220%;padding-left:20px;">
        <a href="/">History of Education in New Brunswick</a>
      </h2>
    ';

    return [
      '#markup' => $this->t($text),
    ];
  }

}
