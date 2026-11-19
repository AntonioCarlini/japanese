// find-grammar-elements lists the @GRMIDX{{...}} entries of a .jhtml file, one
// per line, as "NAME.html: CONTENTS". build-grammar-index.rb reads that output.
// It is the Go port of scripts/find-grammar-elements.rb.
//
// Usage: find-grammar-elements [--include=DIR] FILE.jhtml
//
// For example, grammar-zehi.jhtml contains
//
//	@GRMIDX{{index="@HI{{zehi}}" grammar="@HI{{zehi}}"}}
//
// which gives the line
//
//	grammar-zehi.html: index="@HI{{zehi}}" grammar="@HI{{zehi}}"
package main

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"japanese/internal/rubycompat"
)

// The Ruby loops until no @include is left, so an include that includes itself
// never finishes. Here that is reported as an error after this many passes.
const max_include_passes = 100

var (
	// Same pattern as japanese-to-codes uses. (The two programs each have their own copy.)
	include_re = regexp.MustCompile(`@include\{\{"([^}]+)"\}\}`)

	// The Ruby matches @GRMIDX{{ with /@GRMIDX\{\{/ixm, so the case does not matter here
	// (unlike in japanese-to-codes, where command names are case sensitive).
	grmidx_re = regexp.MustCompile(`(?i)@GRMIDX\{\{`)

	// Opening or closing brackets: used to find the "}}" that matches the "{{".
	bracket_re = regexp.MustCompile(`\{\{|\}\}`)

	// The Ruby has /.jhtml$/ (the dot is not escaped, so it matches any character).
	jhtml_re = regexp.MustCompile(`.jhtml$`)
)

// handle_cli returns the file to process and the include directory.
// Options and the file name may come in either order, as with GetoptLong.
// Like GetoptLong it accepts --include=DIR, --include DIR, an unambiguous
// abbreviation such as --inc, -i DIR and -iDIR.
func handle_cli() (string, string, error) {
	args := os.Args[1:]
	if len(args) == 0 {
		// The Ruby also prints a usage message, but exits with status 0.
		fmt.Fprintf(os.Stderr, "Usage: %s [--include=DIR] FILE.jhtml\n", filepath.Base(os.Args[0]))
		os.Exit(2)
	}

	include_dir := ""
	var rest []string
	for i := 0; i < len(args); i++ {
		arg := args[i]
		switch {
		case arg == "--":
			rest = append(rest, args[i+1:]...)
			i = len(args) // no more options
		case strings.HasPrefix(arg, "--"):
			name, value, has_value := strings.Cut(arg[2:], "=")
			if name == "" || !strings.HasPrefix("include", name) {
				return "", "", fmt.Errorf("unrecognized option `--%s'", name)
			}
			if !has_value {
				if i+1 >= len(args) {
					return "", "", errors.New("option `--include' requires an argument")
				}
				i++
				value = args[i]
			}
			include_dir = value
		case strings.HasPrefix(arg, "-i"):
			value := arg[2:]
			if value == "" {
				if i+1 >= len(args) {
					return "", "", errors.New("option requires an argument -- i")
				}
				i++
				value = args[i]
			}
			include_dir = value
		case len(arg) > 1 && arg[0] == '-':
			return "", "", fmt.Errorf("invalid option -- %c", arg[1])
		default:
			rest = append(rest, arg)
		}
	}

	if len(rest) == 0 {
		return "", "", errors.New("no input file specified")
	}
	return rest[0], include_dir, nil
}

// expand_includes replaces every @include{{"name"}} with the contents of
// include_dir+name, repeating until none is left (an included file may itself
// contain @include).
func expand_includes(file_text string, include_dir string) (string, error) {
	for passes := 1; ; passes++ {
		include_seen := false
		var err error
		file_text, err = rubycompat.GsubFunc(include_re, file_text, func(m []string) (string, error) {
			include_seen = true
			included, err := os.ReadFile(include_dir + m[1])
			if err != nil {
				return "", err
			}
			return string(included), nil
		})
		if err != nil {
			return "", err
		}
		if !include_seen {
			return file_text, nil
		}
		if passes >= max_include_passes {
			return "", errors.New("@include nested too deeply (does a file include itself?)")
		}
	}
}

// html_name_for is the Ruby file.sub(/.jhtml$/, '.html').
func html_name_for(file string) string {
	loc := jhtml_re.FindStringIndex(file)
	if loc == nil {
		return file
	}
	return file[:loc[0]] + ".html" + file[loc[1]:]
}

// ruby_char_range is the Ruby file_text[start .. stop]. The Ruby takes start
// and stop from StringScanner#pos, which counts bytes, but String#[] counts
// characters. The two agree while the text is plain ASCII, which is the usual
// case here. If a non-ASCII character comes before a @GRMIDX, the Ruby picks
// out the wrong text, and this reproduces that, so that the output is the same.
// (To get the intended text instead, slice the string by byte positions.)
func ruby_char_range(chars []rune, start int, stop int) string {
	if start < 0 || start > len(chars) {
		return "" // the Ruby gets nil, which is output as nothing
	}
	if stop >= len(chars) {
		stop = len(chars) - 1
	}
	if stop < start {
		return "" // an empty @GRMIDX{{}}
	}
	return string(chars[start : stop+1])
}

// puts_line adds a newline unless there already is one, like Ruby's puts.
func puts_line(s string) string {
	if strings.HasSuffix(s, "\n") {
		return s
	}
	return s + "\n"
}

// find_grammar_elements returns one line for each @GRMIDX{{...}} in file_text.
// Nested brackets are allowed inside the contents, so the matching "}}" is
// found by counting the "{{" and "}}" seen after the opening "@GRMIDX{{".
func find_grammar_elements(file string, file_text string) (string, error) {
	var output strings.Builder
	chars := []rune(file_text)
	html_name := html_name_for(file)

	pos := 0 // The scan pointer: a byte position in file_text (Ruby: StringScanner#pos)
	for {
		// Start by matching @GRMIDX{{
		loc := grmidx_re.FindStringIndex(file_text[pos:])
		if loc == nil {
			break // Stop if no more @GRMIDX{{...}}
		}
		pos += loc[1]
		close_reqd := 1 // Need one set of closing brackets
		start := pos

		// Now find the matching closing }}
		for close_reqd > 0 {
			// Repeatedly go to the next "{{" or "}}" and count them.
			loc = bracket_re.FindStringIndex(file_text[pos:])
			if loc == nil {
				// The Ruby just exits with status 1 and no message.
				return "", fmt.Errorf("%s: @GRMIDX{{ at offset %d has no matching }}", file, start)
			}
			matched := file_text[pos+loc[0] : pos+loc[1]]
			pos += loc[1]
			if matched == "{{" {
				close_reqd += 1 // Found opening brackets
			} else {
				close_reqd -= 1 // Found closing brackets
			}
			if close_reqd == 0 {
				// pos is one beyond "}}", so back 3 to capture just the contents of @GRMIDX{{...}}
				stop := pos - 3
				contents := ruby_char_range(chars, start, stop)
				output.WriteString(puts_line(html_name + ": " + contents))
			}
		}
	}
	return output.String(), nil
}

func processing() error {
	file, include_dir, err := handle_cli()
	if err != nil {
		return err
	}

	if include_dir != "" && !strings.HasSuffix(include_dir, "/") {
		include_dir += "/"
	}

	// Read the file and process @include statements
	contents, err := os.ReadFile(file)
	if err != nil {
		return err
	}
	file_text, err := expand_includes(string(contents), include_dir)
	if err != nil {
		return err
	}

	// Nothing is written unless the whole file was processed. (The Ruby writes
	// what it has found so far, which can leave a half-written file behind.)
	output, err := find_grammar_elements(file, file_text)
	if err != nil {
		return err
	}
	_, err = os.Stdout.WriteString(output)
	return err
}

func main() {
	if err := processing(); err != nil {
		fmt.Fprintf(os.Stderr, "%s: %v\n", filepath.Base(os.Args[0]), err)
		os.Exit(1)
	}
}
