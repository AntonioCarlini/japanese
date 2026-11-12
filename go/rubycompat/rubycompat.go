// Package rubycompat provides the handful of Ruby String behaviours that the
// ported scripts depend on and that Go's standard library does not match exactly.
package rubycompat

import (
	"regexp"
	"strings"
)

// Ruby's notion of ASCII whitespace (String#strip, String#to_i, \s).
const ruby_whitespace = " \t\n\v\f\r"

// Strip is Ruby's String#strip.
func Strip(s string) string {
	return strings.Trim(s, ruby_whitespace+"\x00")
}

// Chomp is Ruby's String#chomp with the default separator.
func Chomp(s string) string {
	if strings.HasSuffix(s, "\r\n") {
		return s[:len(s)-2]
	}
	if strings.HasSuffix(s, "\n") || strings.HasSuffix(s, "\r") {
		return s[:len(s)-1]
	}
	return s
}

func trim_trailing_empty(parts []string) []string {
	n := len(parts)
	for n > 0 && parts[n-1] == "" {
		n--
	}
	return parts[:n]
}

// SplitString is Ruby's String#split(sep) for a non-blank string separator:
// trailing empty fields are dropped and "" gives an empty result.
func SplitString(s, sep string) []string {
	return trim_trailing_empty(strings.Split(s, sep))
}

// SplitWhitespace is Ruby's String#split(' ') (awk-style, ASCII whitespace).
func SplitWhitespace(s string) []string {
	return strings.FieldsFunc(s, func(r rune) bool {
		return r == ' ' || r == '\t' || r == '\n' || r == '\v' || r == '\f' || r == '\r'
	})
}

// SplitRegexp is Ruby's String#split(regexp): trailing empty fields are
// dropped, a leading empty field is kept and "" gives an empty result.
func SplitRegexp(re *regexp.Regexp, s string) []string {
	if s == "" {
		return []string{}
	}
	return trim_trailing_empty(re.Split(s, -1))
}

func digit_value(c rune) int {
	switch {
	case c >= '0' && c <= '9':
		return int(c - '0')
	case c >= 'a' && c <= 'f':
		return int(c-'a') + 10
	case c >= 'A' && c <= 'F':
		return int(c-'A') + 10
	}
	return -1
}

// ToI is Ruby's String#to_i(base) for base 10 and 16: leading whitespace is
// skipped, an optional sign (and 0x for base 16) is accepted, parsing stops at
// the first invalid character and "no digits" gives 0.
func ToI(s string, base int) int {
	s = strings.TrimLeft(s, ruby_whitespace)
	negative := false
	if strings.HasPrefix(s, "-") {
		negative = true
		s = s[1:]
	} else if strings.HasPrefix(s, "+") {
		s = s[1:]
	}
	if base == 16 && (strings.HasPrefix(s, "0x") || strings.HasPrefix(s, "0X")) {
		s = s[2:]
	}
	n := 0
	after_digit := false
	for _, c := range s {
		d := digit_value(c)
		if d >= 0 && d < base {
			n = n*base + d
			after_digit = true
		} else if c == '_' && after_digit {
			after_digit = false
		} else {
			break
		}
	}
	if negative {
		n = -n
	}
	return n
}

// GsubFunc is the equivalent of Ruby's s.gsub(re) { |match| ... }.
// fn is given the match and its capture groups (m[0] is the whole match, m[1]
// is $1 and so on) and returns the replacement text, which is used literally.
func GsubFunc(re *regexp.Regexp, s string, fn func(m []string) (string, error)) (string, error) {
	var b strings.Builder
	last := 0
	for _, loc := range re.FindAllStringSubmatchIndex(s, -1) {
		m := make([]string, len(loc)/2)
		for i := range m {
			if loc[2*i] >= 0 {
				m[i] = s[loc[2*i]:loc[2*i+1]]
			}
		}
		b.WriteString(s[last:loc[0]])
		replacement, err := fn(m)
		if err != nil {
			return "", err
		}
		b.WriteString(replacement)
		last = loc[1]
	}
	b.WriteString(s[last:])
	return b.String(), nil
}
