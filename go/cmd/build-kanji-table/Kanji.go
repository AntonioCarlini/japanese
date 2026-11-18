package main

// Ported from scripts/Kanji.rb (just the parts the generator needs)

import (
	"fmt"
	"os"
	"strings"
)

// Kanji represents a single kanji.
type Kanji struct {
	english []string
	heisig  int
	idents  []string
	jlpt    int
	jouyou  int
	kunyomi []string
	nanori  []string
	onyomi  []string
	unicode int
}

// add_reading records a reading that uniquely identifies this kanji.
// It is an error if the reading does not show up in onyomi or kunyomi.
func (k *Kanji) add_reading(reading string) error {
	for _, r := range k.onyomi {
		if r == reading {
			k.idents = append(k.idents, reading)
			return nil
		}
	}
	for _, r := range k.kunyomi {
		if r == reading {
			k.idents = append(k.idents, reading)
			return nil
		}
	}

	fmt.Fprintf(os.Stderr, "ONYOMI:  [%s]\n", strings.Join(k.onyomi, " "))
	fmt.Fprintf(os.Stderr, "KUNYOMI: [%s]\n", strings.Join(k.kunyomi, " "))
	return fmt.Errorf("Claimed reading [%s] for [%d] [%d] is wrong", reading, k.heisig, k.unicode)
}
