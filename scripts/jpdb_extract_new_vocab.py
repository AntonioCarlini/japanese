#!/usr/bin/env python3
"""
JPDB Vocab Extractor & Marker

This script automates the extraction of new vocabulary from a specific JPDB.io deck
and optionally marks all new words as "never forget" (known) in that deck. It uses
Selenium with Firefox to interact with JPDB.io directly in a logged-in session.

Features:
- Gather all "New" vocabulary from a given deck, across multiple pages.
- Output vocabulary words with optional reference text for further processing.
- Mark all vocabulary in the deck as known ("never forget") to prevent reviews.

Usage:
    python3 jpdb_extract_new_vocab.py [--gather-vocab] [--mark-vocab-known] [--profile PROFILE] [--deck-id DECK_ID] [--reference REF]

Options:
    --gather-vocab       Extract all new vocabulary from the specified deck and print it.
    --mark-vocab-known   Mark all vocabulary in the deck as "never forget".
    --profile PROFILE    Path to the Firefox profile to use (default: my current FF profile path).
    --deck-id DECK_ID    The JPDB deck ID (default: 1).
    --reference REF      Optional reference text to append to each vocabulary entry.

Notes:
- Both actions can be combined; --gather-vocab will run before --mark-vocab-known.
- For safety, marking vocabulary as known is performed only after extraction if both options are used.
- Limit of 50 pages per extraction is enforced to prevent runaway scraping (this should cover ~2500 words).

Requirements:
- Selenium
- Firefox
- Firefox geckodriver in PATH
"""

import argparse
import time
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.firefox.options import Options


def init_driver(profile_path):
    """Initialise Firefox with the given profile path."""
    #options = Options()
    # options.add_argument("-headless")  # uncomment if you want headless operation
    #options.set_preference("profile", profile_path)
    options = Options()
    options.add_argument("--profile")
    options.add_argument(profile_path)
    options.set_preference("dom.webdriver.enabled", False)
    options.set_preference("useAutomationExtension", False)
    driver = webdriver.Firefox(options=options)
    return driver


def click_new_tab(driver, deck_id):
    """Navigate to the deck and click the 'New' button."""
    driver.get(f"https://jpdb.io/deck?id={deck_id}")
    time.sleep(3)
    new_link = driver.find_element(By.CSS_SELECTOR, f"a[href^='/deck?id={deck_id}'][href*='show_only=new']")
    new_link.click()
    time.sleep(3)


def gather_vocab(driver, deck_id, reference_text=None, page_limit=50):
    """Collect all vocab from the 'New' pages."""
    click_new_tab(driver, deck_id)

    all_vocab = []
    page = 1

    while page <= page_limit:
        print(f"\n🔹 Processing page {page}...")

        vocab_elements = driver.find_elements(By.CSS_SELECTOR, "a[href^='/vocabulary/']")

        for elem in vocab_elements:
            base = driver.execute_script(
                "return arguments[0].innerHTML.replace(/<rt>.*?<\\/rt>/g, '').replace(/<[^>]+>/g, '').trim();",
                elem
            )
            if base and base not in all_vocab:
                all_vocab.append(base)

        # Check for "Next page"
        next_links = driver.find_elements(
            By.CSS_SELECTOR, "div.pagination a[href*='offset='][href*='show_only=new']"
        )
        if not next_links:
            print("✅ No more pages found.")
            break

        next_links[0].click()
        page += 1
        time.sleep(3)

    if page > page_limit:
        print("⚠️ Stopped after 50 pages (safety limit reached — possible infinite loop).")

    print(f"\n✅ Total unique vocab collected: {len(all_vocab)}\n")

    # Output vocab list (with optional reference text)
    for w in all_vocab:
        if reference_text:
            print(f"{w},{reference_text}")
        else:
            print(w)

    return all_vocab


def mark_vocab_known(driver, deck_id):
    """Mark all vocab on all pages as 'never forget'."""
    click_new_tab(driver, deck_id)
    page = 1
    page_limit = 50
    marked_total = 0

    while page <= page_limit:
        print(f"\n🔹 Marking page {page}...")

        # Find all 'Never forget' buttons (adjust selector as needed)
        buttons = driver.find_elements(By.XPATH, "//button[contains(text(),'Never forget')]")
        for btn in buttons:
            driver.execute_script("arguments[0].click();", btn)
            marked_total += 1
            time.sleep(0.2)

        # Check for "Next page"
        next_links = driver.find_elements(
            By.CSS_SELECTOR, "div.pagination a[href*='offset='][href*='show_only=new']"
        )
        if not next_links:
            print("✅ No more pages found to mark.")
            break

        next_links[0].click()
        page += 1
        time.sleep(3)

    if page > page_limit:
        print("⚠️ Stopped after 50 pages (safety limit reached — possible infinite loop).")

    print(f"\n✅ Marked {marked_total} vocab items as 'never forget'.")


def main():
    parser = argparse.ArgumentParser(description="Automate JPDB deck operations.")
    parser.add_argument(
        "--profile",
        default="/home/antonioc/.mozilla/firefox/rin916ju.automation",
        help="Path to your Firefox profile copy (default: /home/yourusername/.mozilla/firefox/jpdb-copy)",
    )
    parser.add_argument(
        "--deck-id",
        default="1",
        help="JPDB deck ID (default: 1)",
    )
    parser.add_argument("--gather-vocab", action="store_true", help="Gather and print all new vocab")
    parser.add_argument("--mark-vocab-known", action="store_true", help="Mark all new vocab as 'never forget'")
    parser.add_argument("--reference", help="Optional reference text to print after each vocab (comma-separated output)")

    args = parser.parse_args()

    print(F"profile is {args.profile}")
    driver = init_driver(args.profile)

    if args.gather_vocab:
        vocab = gather_vocab(driver, args.deck_id, args.reference)
        print(f"\nGathered {len(vocab)} vocab items.")

    if args.mark_vocab_known:
        mark_vocab_known(driver, args.deck_id)

    if not args.gather_vocab and not args.mark_vocab_known:
        print("ℹ️ No action specified. Use --gather-vocab and/or --mark-vocab-known.")

    driver.quit()
    print("\n✅ Finished successfully.")


if __name__ == "__main__":
    main()
