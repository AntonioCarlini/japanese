package main

// Ported from scripts/KatakanaSupport.rb
// (see HiraganaSupport.go for the shared regexps and notes)

import (
	"fmt"
	"regexp"
	"strings"
	"unicode/utf8"
)

var katakana_fi_re = regexp.MustCompile(`(?mi)^fi$`)
var katakana_je_re = regexp.MustCompile(`(?mi)^je$`)
var katakana_sh_ch_j_z_re = regexp.MustCompile(`(?mi)^(sh|ch|j|z)(a|u|o)$`)

var katakana_one = map[string]int{
	"a": 0x30a2, "i": 0x30a4, "u": 0x30a6, "e": 0x30a8, "o": 0x30aa,
	",": 0x3001, ".": 0x3002, "[": 0x300c, "]": 0x300d,
	"-": 0x30FC,
}

var katakana_two = map[string]int{
	"ka": 0x30ab, "ki": 0x30ad, "ku": 0x30af, "ke": 0x30b1, "ko": 0x30b3,
	"ga": 0x30ac, "gi": 0x30ae, "gu": 0x30b0, "ge": 0x30b2, "go": 0x30b4,
	"sa": 0x30b5, "si": 0x30b7, "su": 0x30b9, "se": 0x30bb, "so": 0x30bd,
	"za": 0x30b6, "ji": 0x30b8, "zu": 0x30ba, "ze": 0x30bc, "zo": 0x30be,
	"ta": 0x30bf, "ti": 0x30c1, "tu": 0x30c4, "te": 0x30c6, "to": 0x30c8,
	"da": 0x30c0, "di": 0x30c2, "du": 0x30c5, "de": 0x30c7, "do": 0x30c9,
	"na": 0x30ca, "ni": 0x30cb, "nu": 0x30cc, "ne": 0x30cd, "no": 0x30ce,
	"ha": 0x30cf, "hi": 0x30d2, "fu": 0x30d5, "he": 0x30d8, "ho": 0x30db,
	"ba": 0x30d0, "bi": 0x30d3, "bu": 0x30d6, "be": 0x30d9, "bo": 0x30dc,
	"pa": 0x30d1, "pi": 0x30d4, "pu": 0x30d7, "pe": 0x30da, "po": 0x30dd,
	"ma": 0x30de, "mi": 0x30df, "mu": 0x30e0, "me": 0x30e1, "mo": 0x30e2,
	"ya": 0x30e4, "yu": 0x30e6, "yo": 0x30e8,
	"ra": 0x30e9, "ri": 0x30ea, "ru": 0x30eb, "re": 0x30ec, "ro": 0x30ed,
	"wa": 0x30ef, "wi": 0x30f0, "we": 0x30f1, "wo": 0x30f2,
	"nn": 0x30f3, "n'": 0x30f3,
	"xa": 0x30a1, "xi": 0x30a3, "xu": 0x30a5, "xe": 0x30a7, "xo": 0x30a9,
	// Alternatives below here
	"hu":  0x30d5,
	"shi": 0x30b7, "chi": 0x30c1,
}

var katakana_three = map[string]int{
	"shi": 0x30b7, "chi": 0x30c1, "tsu": 0x30c4,
	"xya": 0x30e3, "xyu": 0x30e5, "xyo": 0x30e7, "xwa": 0x30ee,
}

var katakana_digraph2 = map[string]int{"ya": 0x30e3, "yu": 0x30e5, "yo": 0x30e7}

var katakana_four = map[string]int{"xtsu": 0x30c3}

// convert_to_katakana converts romaji to katakana, returning the result as
// numeric character references. It works exactly like convert_to_hiragana,
// with its own tables and a few extra sequences (fi, je, and "-" for the
// long vowel mark).
func convert_to_katakana(text string) (string, error) {
	one := katakana_one
	two := katakana_two
	three := katakana_three
	digraph2 := katakana_digraph2
	four := katakana_four

	result := ""
	current := ""
	pos := 0
	for _, c := range text {
		pos += 1
		current += string(c)
		if kana_digit_re.MatchString(current) {
			result += current
			current = ""
			continue
		}

		ch := strings.ToLower(current)
		switch utf8.RuneCountInString(current) {
		case 1:
			s, found := one[ch]
			if found {
				// Single char translation works
				result += jp_unicode(s)
				current = ""
			} else if kana_blank_re.MatchString(current) {
				result += current
				current = ""
			} else if kana_non_alnum_re.MatchString(current) {
				result += current
				current = ""
			}
		case 2:
			s, found := two[ch]
			runes := []rune(current)
			if found {
				// Two char translation works
				result += jp_unicode(s)
				current = ""
			} else if runes[0] == runes[1] {
				result += jp_unicode(0x30c3) // Katakana small tsu
				current = string(runes[1])
			} else if (runes[0] == 'n' || runes[0] == 'N') && current != "ny" {
				// n followed by anything other than aiueo or y (nya etc. should be left alone)
				result += jp_unicode(two["nn"])
				current = string(runes[1:])
			}
		case 3:
			s, found := three[ch]
			if found {
				// Three char translation works
				result += jp_unicode(s)
				current = ""
			}
		case 4:
			s, found := four[ch]
			if found {
				// Four char translation works
				result += jp_unicode(s)
				current = ""
			}
		}
		// Look for the hiragana digraphs
		if m := kana_digraph_re.FindStringSubmatch(current); m != nil {
			first := strings.ToLower(m[1] + "i")
			second := strings.ToLower(m[2])
			a, err := jp_unicode_for(two, first)
			if err != nil {
				return "", err
			}
			b, err := jp_unicode_for(digraph2, second)
			if err != nil {
				return "", err
			}
			result += a + b
			current = ""
		} else if katakana_fi_re.MatchString(current) {
			result += jp_unicode(two["hu"]) + jp_unicode(0x30a3)
			current = ""
		} else if katakana_je_re.MatchString(current) {
			result += jp_unicode(two["ji"]) + jp_unicode(0x30a7)
			current = ""
		} else if m := kana_j_vowel_re.FindStringSubmatch(current); m != nil {
			second := "y" + strings.ToLower(m[1])
			a, err := jp_unicode_for(two, "ji")
			if err != nil {
				return "", err
			}
			b, err := jp_unicode_for(digraph2, second)
			if err != nil {
				return "", err
			}
			result += a + b
			current = ""
		} else if m := katakana_sh_ch_j_z_re.FindStringSubmatch(current); m != nil {
			first := strings.ToLower(m[1] + "i")
			second := strings.ToLower("y" + m[2])
			// In Ruby a failed lookup here is rescued and ignored (nothing is appended).
			a, err_a := jp_unicode_for(three, first)
			b, err_b := jp_unicode_for(digraph2, second)
			if err_a == nil && err_b == nil {
				result += a + b
			}
			current = ""
		}

		if utf8.RuneCountInString(current) >= 5 {
			return "", fmt.Errorf("KATAKANA: BROKEN at %d trying to handle [%s]", pos, current)
		}
	}

	if utf8.RuneCountInString(current) == 1 {
		if strings.ToLower(current) == "n" {
			// Handle stray final "n"
			result += jp_unicode(two["nn"])
			current = ""
		} else {
			ch := strings.ToLower(current)
			s, found := one[ch]
			if found {
				// Single char translation works
				result += jp_unicode(s)
				current = ""
			} else if kana_blank_re.MatchString(current) {
				result += current
				current = ""
			} else if kana_non_alnum_re.MatchString(current) {
				result += current
				current = ""
			}
		}
	}

	if current != "" {
		return "", fmt.Errorf("Stray trailing katakana: [%s] in [%s]", current, text)
	}

	return result, nil
}
