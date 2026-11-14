package main

// Ported from scripts/UnicodeSupport.rb

import (
	"fmt"
	"strconv"
)

func jp_unicode(x int) string {
	return "&#x" + strconv.FormatInt(int64(x), 16) + ";"
}

// jp_unicode_for returns jp_unicode(table[key]). In Ruby a missing key gives
// jp_unicode(nil), which raises an obscure exception; here it is an error.
func jp_unicode_for(table map[string]int, key string) (string, error) {
	code, found := table[key]
	if !found {
		return "", fmt.Errorf("no code point defined for [%s]", key)
	}
	return jp_unicode(code), nil
}
