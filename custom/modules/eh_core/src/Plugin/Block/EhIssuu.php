<?php

namespace Drupal\eh_core\Plugin\Block;

use Drupal\Core\Block\BlockBase;

/**
 * Provides an ISSUU banner block for the home page.
 *
 * @Block(
 *   id = "eh_issuu",
 *   admin_label = @Translation("EH ISSUU"),
 *   category = @Translation("Misc"),
 * )
 */
class EhIssuu extends BlockBase {

  /**
   * {@inheritdoc}
   */
  public function build() {
    $text = '
      <p>
        Katherine F.C. MacNaughton, M.A. University of New Brunswick Fredericton,
        New Brunswick, 1947
        <br>
        &nbsp;
      </p>

      <div class="pdf-container">
        <embed src="/sites/default/files/images/MacN1947.pdf#view=FitV&amp;zoom=page-height" width="100%" height="600" type="application/pdf">
      </div>

      <p>
        <br>
        <a href="/MacNTit">HTML</a>
        <br>
        <a href="/sites/default/files/images/MacN1947.pdf">PDF</a><br />
        <a href="/sites/default/files/2016-07/education_history.epub">ePub (for e-readers)</a>
      </p>
    ';

    return [
      '#markup' => $this->t($text),
    ];
  }

}
