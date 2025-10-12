#!/usr/bin/env python3
"""
Given a file of the form:

japanese-expression,reference-text

transform it into a CSV file with the following fields:

1. japanese-expression
2. japanese-expression rendered entriely in hiragana
3. japanese-expression translated into English
4. part of speech
5. source of text (currently blank)
6. blank
7. reference-text

This format is what I need for feeding the generated data into my Anki decks.

Usage:
    python3 produce-anki-csv.py --input path-to-input-text path-to-JMdict-XML-file path-to-csv-file

    path-to-JMdict-XML-file is the JMdict Japanese dictionary, in XML form

"""
import csv
import xml.etree.ElementTree as ET
import sys
import argparse

def load_jmdict(filename):
    print("Loading JMdict XML... this may take a while")
    tree = ET.parse(filename)
    root = tree.getroot()
    
    jmdict_dict = {}

    for entry in root.findall('entry'):
        kanji_elements = entry.findall('k_ele')
        reading_elements = entry.findall('r_ele')
        sense_elements = entry.findall('sense')

        kanji_words = [k.find('keb').text for k in kanji_elements if k.find('keb') is not None]
        readings = [r.find('reb').text for r in reading_elements if r.find('reb') is not None]

        glosses = []
        pos_list = []
        for s in sense_elements:
            for pos in s.findall('pos'):
                pos_list.append(pos.text)
            for gloss in s.findall('gloss'):
                glosses.append(gloss.text)
        
        pos_category = ''
        for p in pos_list:
            if p == 'n':
                pos_category = 'n'
                break
            elif p == 'vs' or p == 'v5s':
                pos_category = 'v5s'
            elif p == 'v1' or p == 'v1t':
                pos_category = 'v1t'
            elif p == 'v5' or p == 'v5t':
                pos_category = 'v5t'
            elif p == 'adj-i':
                pos_category = 'い-adj'
            elif p == 'adj-na':
                pos_category = 'な-adj'
            elif p == 'vs-s':
                pos_category = 'する-ns'
        
        for w in kanji_words + readings:
            if w not in jmdict_dict:
                jmdict_dict[w] = {
                    'reading': readings[0] if readings else '',
                    'glosses': glosses,
                    'pos': pos_category
                }
    print(f"Dictionary loaded with {len(jmdict_dict)} entries.")
    return jmdict_dict

def lookup_word(word, dictionary):
    if word in dictionary:
        entry = dictionary[word]
        reading = entry['reading']
        meanings = entry['glosses'][:3]
        pos = entry['pos']
        if not pos:
            pos = ''
        return reading, meanings, pos
    else:
        return '', [], ''

def main():
    parser = argparse.ArgumentParser(description="Generate CSV from Japanese text with dictionary lookup.")
    parser.add_argument('--input', required=True, help="Path to input text file")
    parser.add_argument('jmdict', help="Path to JMdict XML file")
    parser.add_argument('output', help="Path to output CSV file")
    args = parser.parse_args()

    jmdict_dict = load_jmdict(args.jmdict)

    with open(args.input, encoding='utf-8') as infile, \
         open(args.output, 'w', encoding='utf-8', newline='') as outfile:
        writer = csv.writer(outfile, quoting=csv.QUOTE_ALL)
        for line in infile:
            line = line.strip()
            if not line or ',' not in line:
                continue
            jp_word, ref = line.split(',', 1)
            reading, meanings, pos = lookup_word(jp_word, jmdict_dict)
            meanings_str = "; ".join(meanings) if meanings else "No translation found"
            writer.writerow([jp_word, reading, meanings_str, pos, "", "", ref])
    print(f"CSV output written to {args.output}")

if __name__ == '__main__':
    main()
