#!/usr/bin/env python3
"""
Find all Anki notes whose Front field contains only katakana.

Usage:
    python3 find_katakana_only_cards.py /path/to/collection.anki2

Example:
    python3 find_katakana_only_cards.py ~/.local/share/Anki2/User\ 1/collection.anki2

Notes:
- The script assumes the field name is 'Front'.
- Works on Anki 2.1+ / 24.x formats (SQLite3 database).
"""

import sqlite3
import re
import argparse
import sys

def main():
    parser = argparse.ArgumentParser(description="Find katakana-only entries in a specific Anki deck (optionally only new cards).")
    parser.add_argument("anki_db", help="Path to Anki collection.anki2 database")
    parser.add_argument("--deck", required=True, help="Full deck name (use the name from Anki’s Rename dialog)")
    args = parser.parse_args()

    conn = sqlite3.connect(args.anki_db)
    cur = conn.cursor()

    # List available decks
    cur.execute("SELECT id, name FROM decks")
    decks = cur.fetchall()

    print("Available decks:")
    for d in decks:
        print(f"  - [{d[1]}]")

    # Normalise deck name: Anki internally uses '\x1f' instead of '::'
    normalized_deck_name = args.deck.replace("::", "\x1f")

    deck_row = next((d for d in decks if d[1] == normalized_deck_name), None)
    if not deck_row:
        print(f"\nDeck not found: {args.deck}")
        sys.exit(1)

    deck_id, deck_name = deck_row
    print(f"\nMatched deck '{args.deck}' (id={deck_id})")

    # Query for notes in this deck where the card is new (queue=0)
    cur.execute(
        """
        SELECT notes.id, notes.flds
        FROM notes
        JOIN cards ON notes.id = cards.nid
        WHERE cards.did = ?
          AND cards.queue = 0
        """,
        (deck_id,),
    )

    katakana_re = re.compile(r"^[ァ-ヶー]+$")
    found = []

    for note_id, fields in cur.fetchall():
        # Split note fields (usually separated by '\x1f')
        front = fields.split('\x1f')[0].strip()
        # print(f"Found front[{front}]")  # <===== debug line
        if katakana_re.match(front):
            found.append((note_id, front))

    print("\n--- Katakana-only entries ---")
    for nid, front in found:
        print(front)

    print(f"\nTotal katakana-only entries found: {len(found)}")

if __name__ == "__main__":
    main()
