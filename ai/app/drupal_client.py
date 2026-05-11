import os
import requests

DRUPAL_BOOK_JSON_URL = os.getenv("DRUPAL_BOOK_JSON_URL", "http://drupal/api/book-pages")

def fetch_book_pages():
    response = requests.get(DRUPAL_BOOK_JSON_URL, timeout=30)
    response.raise_for_status()
    return response.json()