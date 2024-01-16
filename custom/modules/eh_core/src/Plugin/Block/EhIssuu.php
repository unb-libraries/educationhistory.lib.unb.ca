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

      <div style="position:relative;padding-top:max(60%,326px);height:0;width:100%"><iframe allow="clipboard-write" sandbox="allow-top-navigation allow-top-navigation-by-user-activation allow-downloads allow-scripts allow-same-origin allow-popups allow-modals allow-popups-to-escape-sandbox" allowfullscreen="true" style="position:absolute;border:none;width:100%;height:100%;left:0;right:0;top:0;bottom:0;" src="https://e.issuu.com/embed.html?d=macn1947&u=unb-etc"></iframe></div>

      <p>
      <br>
      <a href="/MacNTit">HTML</a>
      <br>
      <a href="https://issuu.com/unb-etc/docs/macnaughton?printButtonEnabled=false&amp;shareButtonEnabled=false&amp;searchButtonEnabled=false&amp;backgroundColor=">
      Page Turner
      </a>
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
