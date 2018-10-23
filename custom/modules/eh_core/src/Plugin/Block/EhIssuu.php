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

      <div class="issuuembed" data-configid="0/37176230" style="width:525px; height:400px;">
      &nbsp;
      </div>

      <script type="text/javascript" src="//e.issuu.com/embed.js" async="true">
      </script>

      <p>
      <br>
      <a href="/MacNTit">HTML</a>
      <br>
      <a href="https://issuu.com/unb-etc/docs/macnaughton?printButtonEnabled=false&amp;shareButtonEnabled=false&amp;searchButtonEnabled=false&amp;backgroundColor=">
      Page Turner
      </a>
      <br>
      <a href="/sites/default/files/2016-07/education_history.pdf">PDF</a><br />
      <a href="/sites/default/files/2016-07/education_history.epub">ePub (for e-readers)</a>
      </p>
    ';

    return [
      '#markup' => $this->t($text),
    ];
  }

}
