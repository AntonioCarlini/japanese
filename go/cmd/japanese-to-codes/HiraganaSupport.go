package main

// Ported from scripts/HiraganaSupport.rb
//
// Notes on the regexps (shared with KatakanaSupport.go):
//  - Ruby's ^ and $ match at line boundaries, hence (?m).
//  - Ruby's \s includes \v, which Go's \s does not, hence the explicit class.
//  - Ruby's [[:alnum:]] is Unicode aware, hence \p{L}\p{M}\p{Nd}.
//
// $UNICODE_2_HI_JHTML and convert_unicode_to_hiragana_jhtml are not used by
// japanese-to-codes.rb and have not been ported.

import (
	"fmt"
	"regexp"
	"strings"
	"unicode/utf8"
)

var kana_digit_re = regexp.MustCompile(`(?m)^[0-9]$`)
var kana_blank_re = regexp.MustCompile(`(?m)^[ \t\r\n\f\v]*$`)
var kana_non_alnum_re = regexp.MustCompile(`[^\p{L}\p{M}\p{Nd}]`)
var kana_digraph_re = regexp.MustCompile(`(?mi)^(k|sh|ch|n|h|m|r|g|j|b|p)(ya|yu|yo)$`)
var kana_j_vowel_re = regexp.MustCompile(`(?mi)^j(a|u|o)$`)
var hiragana_sh_ch_j_re = regexp.MustCompile(`(?m)^(sh|ch|j)(a|u|o)$`)
var hiragana_ja_ju_jo_re = regexp.MustCompile(`(?m)^(ja|ju|jo)$`)

var hiragana_one = map[string]int{
	"a": 0x3042, "i": 0x3044, "u": 0x3046, "e": 0x3048, "o": 0x304a,
	",": 0x3001, ".": 0x3002, "[": 0x300c, "]": 0x300d,
}

var hiragana_two = map[string]int{
	"ka": 0x304b, "ki": 0x304d, "ku": 0x304f, "ke": 0x3051, "ko": 0x3053,
	"ga": 0x304c, "gi": 0x304e, "gu": 0x3050, "ge": 0x3052, "go": 0x3054,
	"sa": 0x3055, "si": 0x3057, "su": 0x3059, "se": 0x305b, "so": 0x305d,
	"za": 0x3056, "ji": 0x3058, "zu": 0x305a, "ze": 0x305c, "zo": 0x305e,
	"ta": 0x305f, "ti": 0x3061, "tu": 0x3064, "te": 0x3066, "to": 0x3068,
	"da": 0x3060, "di": 0x3062, "du": 0x3065, "de": 0x3067, "do": 0x3069,
	"na": 0x306a, "ni": 0x306b, "nu": 0x306c, "ne": 0x306d, "no": 0x306e,
	"ha": 0x306f, "hi": 0x3072, "fu": 0x3075, "he": 0x3078, "ho": 0x307b,
	"ba": 0x3070, "bi": 0x3073, "bu": 0x3076, "be": 0x3079, "bo": 0x307c,
	"pa": 0x3071, "pi": 0x3074, "pu": 0x3077, "pe": 0x307a, "po": 0x307d,
	"ma": 0x307e, "mi": 0x307f, "mu": 0x3080, "me": 0x3081, "mo": 0x3082,
	"ya": 0x3084, "yu": 0x3086, "yo": 0x3088,
	"ra": 0x3089, "ri": 0x308a, "ru": 0x308b, "re": 0x308c, "ro": 0x308d,
	"wa": 0x308f, "wi": 0x3090, "we": 0x3091, "wo": 0x3092,
	"nn": 0x3093, "n'": 0x3093,
	// NOTE: "xe" has the same code as "xu" in the Ruby (probably a typo for 0x3047). Preserved.
	"xa": 0x3041, "xi": 0x3043, "xu": 0x3045, "xe": 0x3045, "xo": 0x3049,
	"vu": 0x3094,
	// Alternatives below here
	"hu": 0x3075,
}

var hiragana_three = map[string]int{
	"shi": 0x3057, "chi": 0x3061, "tsu": 0x3064,
	"xya": 0x3083, "xyu": 0x3085, "xyo": 0x3087, "xwa": 0x308e,
}

var hiragana_digraph2 = map[string]int{"ya": 0x3083, "yu": 0x3085, "yo": 0x3087}

var hiragana_four = map[string]int{"xtsu": 0x3063}

// convert_to_hiragana converts romaji to hiragana, returning the result as
// numeric character references (e.g. "ka" gives "&#x304b;").
//
// The text is read one character at a time into current, which holds the
// characters not yet translated: one, two, three or four letter sequences are
// looked up in the tables above, and the digraphs (kya, sha, ja ...) are
// recognised by regexp. Anything that is neither a letter nor a known
// sequence is passed through as it is.
func convert_to_hiragana(text string) (string, error) {
	one := hiragana_one
	two := hiragana_two
	three := hiragana_three
	digraph2 := hiragana_digraph2
	four := hiragana_four
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
				result += jp_unicode(0x3063)
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
		} else if m := hiragana_sh_ch_j_re.FindStringSubmatch(current); m != nil {
			first := m[1] + "i"
			second := "y" + m[2]
			// In Ruby a failed lookup here is rescued and ignored (nothing is appended).
			a, err_a := jp_unicode_for(three, first)
			b, err_b := jp_unicode_for(digraph2, second)
			if err_a == nil && err_b == nil {
				result += a + b
			}
			current = ""
		} else if m := hiragana_ja_ju_jo_re.FindStringSubmatch(current); m != nil {
			// Unreachable in practice: the kana_j_vowel_re branch above catches these.
			second := strings.ToLower(m[1])
			ss := strings.Replace(second, "j", "y", 1)
			a, err := jp_unicode_for(two, "ji")
			if err != nil {
				return "", err
			}
			b, err := jp_unicode_for(digraph2, ss)
			if err != nil {
				return "", err
			}
			result += a + b
		}

		if utf8.RuneCountInString(current) >= 5 {
			return "", fmt.Errorf("HIRAGANA: BROKEN at %d trying to handle [%s] in [%s]", pos, current, text)
		}
	}

	if utf8.RuneCountInString(current) == 1 {
		if current == "n" {
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
		return "", fmt.Errorf("Stray trailing hiragana: [%s] in [%s]", current, text)
	}

	return result, nil
}

// hiragana_const converts a fixed, known-good string. An error here would be a
// programming mistake in this program, not a problem with the input.
func hiragana_const(text string) string {
	result, err := convert_to_hiragana(text)
	if err != nil {
		panic(err)
	}
	return result
}
