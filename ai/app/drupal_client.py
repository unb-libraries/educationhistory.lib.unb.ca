import os
import requests

# The Drupal container's service name on the compose network. Overridden by
# env/ai.env; the default is here so the module is importable without it.
DRUPAL_BOOK_JSON_URL = os.getenv(
    "DRUPAL_BOOK_JSON_URL",
    "http://educationhistory-lib-unb-ca/api/book-pages",
)

def fetch_book_pages():
    response = requests.get(DRUPAL_BOOK_JSON_URL, timeout=30)
    response.raise_for_status()
    return response.json()