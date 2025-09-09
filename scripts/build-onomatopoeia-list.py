"""
This script helps to produce a YAML file containing information about a set of Japanese onomatopoeia.

The purpose is to build a YAML file containing information about these onomatopoeia, which will be used by another script to produce a revision web page.

--words: A text file holding a list of onomatopoeia, one per line
--kanji: A comma-delimited CSV file holding lines each of which are a word, its rendering in kana and its definition; further fields are ignored
--sentences: A comma-delimited CSV file holding  a sentence, the sentence in kana and an English translation; further fields are ignored
--output: The output YAML file

The inputs to --kanji and --sentences are expected to be a "Notes" export from Anki.

The intention is to take the list of onomatopoeia and record a definition and a sentence for each.

This information could then be post-processed to produce a web page to help with remembering thes eitems.
"""

import csv
import yaml
import argparse

def main():
    parser = argparse.ArgumentParser(description="Extract vocab definitions and example sentences into YAML.")
    parser.add_argument("--words", required=True, help="File with candidate words (one per line)")
    parser.add_argument("--kanji", required=True, help="Kanji deck CSV file (word, kana, definition, ...)")
    parser.add_argument("--sentences", required=True, help="Sentence deck CSV file (sentence, hiragana, english)")
    parser.add_argument("--output", required=True, help="Output YAML file")
    args = parser.parse_args()

    # Load candidates
    with open(args.words, encoding="utf-8") as f:
        candidates = [line.strip() for line in f if line.strip()]

    # Load kanji deck into dict {word: (kana, definition)}
    kanji_definitions = {}
    with open(args.kanji, encoding="utf-8") as f:
        reader = csv.reader(f, delimiter="\t")
        for row in reader:
            if len(row) >= 3:
                word, kana, definition = row[0], row[1], row[2]
                kanji_definitions[word] = (kana, definition)

    # Load sentences
    sentences = []
    with open(args.sentences, encoding="utf-8") as f:
        reader = csv.reader(f, delimiter="\t")
        for row in reader:
            if len(row) >= 3:
                sentence, hiragana, english = row[0], row[1], row[2]
                sentences.append((sentence, hiragana, english))

    # Build YAML structure
    output = {}
    for word in candidates:
        kana, definition = kanji_definitions.get(word, ("MISSING KANA", "MISSING DEFINITION"))
        word_sentences = [
            {"jp": s, "hiragana": h, "english": e}
            for s, h, e in sentences
            if word in s
        ]
        output[word] = {
            "kana": kana,
            'category': "",
            "definition": definition,
            "sentences": word_sentences
        }

    # Write YAML
    with open(args.output, "w", encoding="utf-8") as f:
        yaml.dump(output, f, allow_unicode=True, sort_keys=False)

if __name__ == "__main__":
    main()
