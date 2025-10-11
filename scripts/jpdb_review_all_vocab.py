#!/usr/bin/env python3
"""
Automatically reviews all available vocab on jpdb.io by clicking
"Show answer" then marking the card with a chosen grade button (e.g. "Easy").

Usage:
    python jpdb_review_all_vocab.py --profile /path/to/firefox/profile [--grade "✔ Easy"]
"""

import time
import argparse
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.firefox.options import Options
from selenium.common.exceptions import NoSuchElementException, ElementClickInterceptedException

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


def start_firefox(profile_path: str):
    options = Options()
    options.set_preference("profile", profile_path)
    driver = webdriver.Firefox(options=options)
    driver.get("https://jpdb.io/learn")
    return driver

def review_all(driver, grade_label="✔ Easy"):
    """Click 'Start Reviewing', then iterate through all available reviews."""
    print(f"Starting JPDB review session using grade: {grade_label!r}\n")

    driver.get("https://jpdb.io/learn")

    # Wait for page load
    time.sleep(2)

    # Step 1: Click "Start reviewing" if visible
    try:
        start_button = driver.find_element(By.XPATH, "//input[@value='Start reviewing']")
        driver.execute_script("arguments[0].click();", start_button)
        print("Clicked 'Start reviewing' button.")
        time.sleep(2)
    except NoSuchElementException:
        print("No 'Start reviewing' button found — maybe already on review page.")

    reviewed = 0

    while True:
        # Step 2: Show answer
        try:
            show_answer = driver.find_element(By.ID, "show-answer")
            driver.execute_script("arguments[0].click();", show_answer)
            time.sleep(0.4)
        except NoSuchElementException:
            print("No 'Show answer' button — maybe no more reviews.")
            break
        except ElementClickInterceptedException:
            print("Click intercepted, retrying...")
            time.sleep(1)
            continue

        # Step 3: Find the grade button (e.g. ✔ Easy, OK, Hard, etc.)
        try:
            grade_btn = driver.find_element(By.XPATH, f"//input[@type='submit' and @value='{grade_label}']")
            driver.execute_script("arguments[0].click();", grade_btn)
            reviewed += 1
            print(f"Reviewed {reviewed} cards...", end="\r")
            time.sleep(0.5)
        except NoSuchElementException:
            print(f"Could not find grade button with label {grade_label!r}.")
            break

        # Step 4: Wait for next card to load
        time.sleep(1)


    print(f"\nFinished reviewing {reviewed} cards total.")
    return reviewed


def main():
    parser = argparse.ArgumentParser(description="Automatically review all due vocab on jpdb.io.")
    parser.add_argument(
        "--profile",
        default="/home/antonioc/.mozilla/firefox/rin916ju.automation",
        help="Path to your Firefox profile copy (default: /home/yourusername/.mozilla/firefox/jpdb-copy)",
    )
    parser.add_argument("--grade", default="✔ Easy", help="Grade button label to click (default: '✔ Easy')")
    args = parser.parse_args()

    print(f"profile is {args.profile}")
    driver = init_driver(args.profile)

    try:
        review_all(driver, args.grade)
    finally:
        print("\nClosing browser...")
        driver.quit()


if __name__ == "__main__":
    main()
