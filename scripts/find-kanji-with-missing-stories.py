#!/usr/bin/env python3
"""

Purpose:
    Identify kanji that appear in a text file (which is likely to be an Anki deck dump, but could be anything)
    but do not exist  in a koohii.com story CSV file. This helps locate characters that lack
    mnemonic stories for study or import.

Usage:
    python3 find-kanji-with-missing-stories.py --text <anki_text_dump.txt> --stories <koohii_stories.csv>

Arguments:
    --text      Path to a plain text file (e.g. exported Anki deck content)
    --stories   Path to a Koohii CSV file where the second column contains kanji

Output:
    Prints a list of kanji found in the text file that have no matching entry in the story file.

"""

import argparse
import csv
import re

def extract_kanji(text):
    """Extract all unique kanji characters from a text block."""
    return set(re.findall(r'[\u4E00-\u9FFF]', text))

def load_stories(stories_path):
    """Load Koohii stories into a dict {kanji: frame_number}."""
    stories = {}
    with open(stories_path, encoding='utf-8') as f:
        reader = csv.reader(f)
        for row in reader:
            if len(row) < 2:
                continue
            try:
                frame = int(row[0])
            except ValueError:
                continue  # skip malformed header or lines
            kanji = row[1].strip()
            stories[kanji] = frame
    return stories

def main():
    parser = argparse.ArgumentParser(description="Find kanji that appear in text but have no Koohii story.")
    parser.add_argument("--text", required=True, help="Path to the Anki deck text dump")
    parser.add_argument("--stories", required=True, help="Path to the Koohii stories CSV")
    args = parser.parse_args()

    # Load stories
    stories = load_stories(args.stories)
    story_kanji = set(stories.keys())

    # Load text and extract kanji
    with open(args.text, encoding='utf-8') as f:
        text = f.read()
    text_kanji = extract_kanji(text)

    # Find kanji missing from story list
    missing = text_kanji - story_kanji

    # Sort by frame number if known, else push to end
    sorted_missing = sorted(
        missing,
        key=lambda k: stories.get(k, 999999)
    )

    print("Kanji with no story:")
    for k in sorted_missing:
        frame = stories.get(k, None)
        if frame is not None:
            print(f"{frame}: {k}")
        else:
            print(f"(no frame): {k}")

if __name__ == "__main__":
    main()
