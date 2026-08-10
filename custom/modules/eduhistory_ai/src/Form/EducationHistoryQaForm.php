<?php

namespace Drupal\eduhistory_ai\Form;

use Drupal\Core\Form\FormBase;
use Drupal\Core\Form\FormStateInterface;
use GuzzleHttp\Exception\RequestException;

class EducationHistoryQaForm extends FormBase {

  public function getFormId(): string {
    return 'eduhistory_ai_question_form';
  }

  public function buildForm(array $form, FormStateInterface $form_state): array {
    $form['question'] = [
      '#type' => 'textarea',
      '#title' => $this->t('Ask a question about education history'),
      '#description' => $this->t('Ask a question about the education history book and receive an answer based on its contents.'),
      '#required' => TRUE,
      '#rows' => 4,
      '#default_value' => $form_state->getValue('question') ?? '',
    ];

    $form['actions'] = [
      '#type' => 'actions',
    ];

    $form['actions']['submit'] = [
      '#type' => 'submit',
      '#value' => $this->t('Ask'),
      '#button_type' => 'primary',
    ];

    $answer = $form_state->get('answer');
    $sources = $form_state->get('sources');

    if ($answer) {
      $form['answer'] = [
        '#type' => 'details',
        '#title' => $this->t('Answer'),
        '#open' => TRUE,
      ];

      $form['answer']['content'] = [
        '#markup' => '<p>' . nl2br(htmlspecialchars($answer)) . '</p>',
      ];
    }

    if (!empty($sources) && is_array($sources)) {
      $items = [];

      // Several retrieved excerpts often come from the same printed page.
      // Listing that page once keeps the citation list readable.
      $seen = [];

      foreach ($sources as $source) {
        $title = $source['title'] ?? 'Untitled';
        $page = $source['printed_page'] ?? NULL;
        $url = $source['url'] ?? '#';

        $key = $url;
        if (isset($seen[$key])) {
          continue;
        }
        $seen[$key] = TRUE;

        $label = $page
          ? $this->t('@title, p. @page', ['@title' => $title, '@page' => $page])
          : $title;

        $links = [
          '<a href="' . htmlspecialchars($url) . '">' . htmlspecialchars((string) $label) . '</a>',
        ];

        // The second link opens the scanned 1947 original at the same page,
        // so a reader can check the passage against the printed book.
        if (!empty($source['scan_url'])) {
          $links[] = '<a href="' . htmlspecialchars($source['scan_url']) . '">'
            . htmlspecialchars((string) $this->t('scan')) . '</a>';
        }

        $items[] = implode(' &middot; ', $links);
      }

      $form['sources'] = [
        '#type' => 'details',
        '#title' => $this->t('Sources'),
        '#open' => TRUE,
      ];

      $form['sources']['content'] = [
        '#markup' => '<ul><li>' . implode('</li><li>', $items) . '</li></ul>',
      ];
    }

    return $form;
  }

  public function submitForm(array &$form, FormStateInterface $form_state): void {
    $question = trim((string) $form_state->getValue('question'));

    try {
      $client = \Drupal::httpClient();

      $response = $client->post('http://ai-api:8000/ask', [
        'headers' => [
          'Content-Type' => 'application/json',
        ],
        'json' => [
          'question' => $question,
        ],
        'timeout' => 120,
      ]);

      $data = json_decode((string) $response->getBody(), TRUE);

      $form_state->set('answer', $data['answer'] ?? 'No answer returned.');
      $form_state->set('sources', $data['sources'] ?? []);
      $form_state->setRebuild(TRUE);
    }
    catch (RequestException $e) {
      $this->messenger()->addError($this->t('Could not contact the education history AI service.'));
    }
    catch (\Throwable $e) {
      $this->messenger()->addError($this->t('An unexpected error occurred: @message', [
        '@message' => $e->getMessage(),
      ]));
    }
  }

}