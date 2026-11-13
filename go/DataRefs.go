package main

// Ported from scripts/DataRefs.rb (reading only; write_file is not used here)
//
// The file format is a number of fields separated by "|" characters:
//  - Reference ident
//  - Reference text (may contain kanji, kana etc.)
//  - Optional alternate text to display when hovering
//
// If an ident appears more than once, the last definition wins (as in the Ruby).

import (
	"fmt"
	"os"
	"regexp"
	"strings"

	"japanese/rubycompat"
)

type Reference struct {
	ident     string // name by which the Reference is identified
	text      string // text which is used to replace the reference
	alternate string // "hover-over" alternate text
}

type DataRefs struct {
	refs map[string]*Reference
}

// The Ruby has /^ \s+ #/ here (no /x flag), i.e. a space, whitespace, a space, then '#'.
var refs_comment_re = regexp.MustCompile(`^ [ \t\r\n\f\v]+ #`)

func DataRefs_create_from_file(filename string) (*DataRefs, error) {
	refs_data := &DataRefs{refs: make(map[string]*Reference)}

	contents, err := os.ReadFile(filename)
	if err != nil {
		return nil, err
	}

	line_num := 0
	for _, line := range strings.SplitAfter(string(contents), "\n") {
		if line == "" {
			continue
		}
		line = rubycompat.Chomp(line)
		line_num += 1

		// Skip commented out lines
		if refs_comment_re.MatchString(line) {
			continue
		}

		// The Ruby crashes on a blank line; here it is simply skipped.
		if rubycompat.Strip(line) == "" {
			continue
		}

		fields := rubycompat.SplitString(line, "|")
		if len(fields) < 2 {
			return nil, fmt.Errorf("%s: line %d: expected \"ident | text | alternate\" but saw [%s]", filename, line_num, line)
		}

		ident := rubycompat.Strip(fields[0])
		text := rubycompat.Strip(fields[1])
		alternate := ""
		if len(fields) > 2 {
			alternate = rubycompat.Strip(fields[2])
		}

		// Keep the reference in a hash
		refs_data.refs[ident] = &Reference{ident: ident, text: text, alternate: alternate}
	}

	return refs_data, nil
}
