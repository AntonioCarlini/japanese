package main

// Ported from scripts/RadicalSupport.rb and scripts/Radical.rb
// The table itself is in RadicalData.go

import (
	"regexp"
	"strings"

	"japanese/rubycompat"
)

// A single radical. unicode is only meaningful if has_unicode is true
// (in Ruby it is nil when the kanji.data lookup failed).
type Radical struct {
	english     string
	reading     string
	unicode     int
	has_unicode bool
}

type RD struct {
	radical map[string]*Radical
}

// RD is a Singleton in the Ruby: it is built the first time it is needed, and
// building it does one kanji lookup per keyword-based entry (so any keyword
// missing from kanji.data is reported on stderr at that point).
var rd_instance *RD

func RD_instance() *RD {
	if rd_instance == nil {
		rd_instance = new_RD()
	}
	return rd_instance
}

func new_RD() *RD {
	rd := &RD{radical: make(map[string]*Radical)}
	for _, e := range radical_entries {
		code := e.unicode
		found := true
		if e.keyword != "" {
			code, found = find_kanji_unicode_from_keyword(e.keyword)
		}
		rd.radical[e.english] = &Radical{english: e.english, reading: e.reading, unicode: code, has_unicode: found}
	}
	return rd
}

func find_radical_unicode_from_keyword(keyword string) (int, bool) {
	r, found := RD_instance().radical[keyword]
	if !found || !r.has_unicode {
		return 0, false
	}
	return r.unicode, true
}

var radical_word_re = regexp.MustCompile(`['()/a-zA-Z0-9.*-]+`)

func convert_to_radical(text string) string {
	converted, _ := rubycompat.GsubFunc(radical_word_re, text, func(m []string) (string, error) {
		word := m[0]
		result := ""
		code, found := find_radical_unicode_from_keyword(strings.ToLower(word))
		if !found {
			result += "&lt;UNKNOWN RADICAL [" + word + "]&gt;"
		} else {
			result += jp_unicode(code)
		}
		return result, nil
	})
	return strings.ReplaceAll(converted, "^", "")
}
