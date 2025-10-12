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
    """Return a set of all CJK Unified Ideograph characters (kanji) in the text."""
    return set(re.findall(r'[\u4E00-\u9FFF]', text))

def load_story_kanji(story_file):
    """Load kanji from the 2nd field of the koohii story CSV file."""
    story_kanji = set()
    with open(story_file, newline='', encoding='utf-8') as f:
        reader = csv.reader(f)
        for row in reader:
            if len(row) >= 2:
                kanji = row[1].strip()
                if re.fullmatch(r'[\u4E00-\u9FFF]', kanji):
                    story_kanji.add(kanji)
    return story_kanji

def main():
    parser = argparse.ArgumentParser(
        description="Find kanji in a text that are missing from a koohii story file."
    )
    parser.add_argument("--text", required=True, help="Path to text dump file (e.g. from Anki).")
    parser.add_argument("--stories", required=True, help="Path to koohii story CSV file.")
    args = parser.parse_args()

    # Load the text and extract kanji
    with open(args.text, encoding='utf-8') as f:
        text = f.read()
    text_kanji = extract_kanji(text)

    # Load the story kanji
    story_kanji = load_story_kanji(args.stories)

    # Find missing kanji
    missing = sorted(text_kanji - story_kanji)

    if missing:
        print("Kanji with no story:")
        print(" ".join(missing))
    else:
        print("All kanji in your text have stories.")

if __name__ == "__main__":
    main()
