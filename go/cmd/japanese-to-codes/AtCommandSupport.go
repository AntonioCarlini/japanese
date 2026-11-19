package main

// Ported from scripts/AtCommandSupport.rb
//
// This file implements the @COMMAND{{...}} processor. The text is scanned for
// "@NAME{{" and "}}" tokens, using a stack to handle nesting. When a "}}" is
// seen, the items back to the matching "@NAME{{" are handed to the handler for
// that command, and the handler's result replaces them on the stack.
//
// Differences from the Ruby that do not change the output of a successful run:
//  - Ruby exceptions become returned errors.
//  - Ruby symbols (:process_hiragana) are strings, and "send" is a map lookup.
//  - The Ruby Text/DoneText/Operation classes share the Item interface.

import (
	"errors"
	"fmt"
	"os"
	"regexp"
	"strings"

	"japanese/internal/rubycompat"
)

// The Ruby builds its regexps from these pieces (Regexp.escape'd brackets).
// The Ruby uses the flags /ixm; none of them affect these patterns (there are
// no letters to fold, no whitespace to ignore and no dots).
var (
	OPENING_BRACKETS = regexp.QuoteMeta("{{")
	CLOSING_BRACKETS = regexp.QuoteMeta("}}")

	OPENING_REGEXP = `@\w{1,15}` + OPENING_BRACKETS
	CLOSING_REGEXP = CLOSING_BRACKETS
)

var (
	opening_re = regexp.MustCompile(OPENING_REGEXP)
	closing_re = regexp.MustCompile(CLOSING_REGEXP)
	token_re   = regexp.MustCompile(`(` + OPENING_REGEXP + `|` + CLOSING_REGEXP + `)`)
	command_re = regexp.MustCompile(`@(.*)` + OPENING_BRACKETS)
	nsv_re     = regexp.MustCompile(`^(N|V|S)(\d*)$`)
	v_digit_re = regexp.MustCompile(`^V\d$`)
	ref_re     = regexp.MustCompile(`@(REF|UCREF)\{\{([^}]+)\}\}`)

	// The Ruby splits @BGRNDSTART names with /\s*,\s* / and that pattern has a
	// literal space at the end (there is no /x flag). That looks accidental, but
	// it is what the Ruby does, so "a, b" splits and "a,b" does not.
	background_split_re = regexp.MustCompile(`[ \t\r\n\f\v]*,[ \t\r\n\f\v]*[ ]`)
)

// fail_on_error is the Ruby global $fail_on_error.
var fail_on_error = false

// Item is one entry on the processing stack: a Text, a DoneText or an Operation.
type Item interface {
	text() string       // the text held (empty for an Operation)
	operation() string  // the name of the handler (empty for text)
	code() string       // the command name, e.g. "HI" (empty for text)
	is_text() bool      // Ruby: text? (text and done-text, as opposed to an operation)
	is_op() bool        // Ruby: op?
	is_processed() bool // Ruby: processed?
	display() string    // description used by dump_stack
}

// display_text shortens text for display: the first 31 characters, with
// newlines shown as "_" and "..." added if the text was longer than 30.
func display_text(s string) string {
	runes := []rune(s)
	shown := s
	if len(runes) > 31 {
		shown = string(runes[:31])
	}
	shown = strings.ReplaceAll(shown, "\n", "_")
	if len(runes) > 30 {
		shown += "..."
	}
	return shown
}

// Text holds text that may require further processing.
type Text struct {
	str string
}

func new_text(s string) *Text      { return &Text{str: s} }
func (t *Text) text() string       { return t.str }
func (t *Text) operation() string  { return "" }
func (t *Text) code() string       { return "" }
func (t *Text) is_text() bool      { return true }
func (t *Text) is_op() bool        { return false }
func (t *Text) is_processed() bool { return false }
func (t *Text) display() string    { return "Text:        " + display_text(t.str) }

// DoneText holds text that requires no further processing.
type DoneText struct {
	str string
}

func new_done_text(s string) *DoneText { return &DoneText{str: s} }
func (d *DoneText) text() string       { return d.str }
func (d *DoneText) operation() string  { return "" }
func (d *DoneText) code() string       { return "" }
func (d *DoneText) is_text() bool      { return true }
func (d *DoneText) is_op() bool        { return false }
func (d *DoneText) is_processed() bool { return true }
func (d *DoneText) display() string    { return "DoneText:    " + display_text(d.str) }

// Operation describes an operation: the name of its handler (a key of
// op_table) and the command that started it (e.g. "HI" for @HI{{).
type Operation struct {
	operation_name string
	code_str       string
}

func new_operation(operation_name, code string) *Operation {
	return &Operation{operation_name: operation_name, code_str: code}
}
func (o *Operation) text() string       { return "" }
func (o *Operation) operation() string  { return o.operation_name }
func (o *Operation) code() string       { return o.code_str }
func (o *Operation) is_text() bool      { return false }
func (o *Operation) is_op() bool        { return true }
func (o *Operation) is_processed() bool { return false }
func (o *Operation) display() string    { return "Operation:   " + o.operation_name }

// Divs holds the DIV settings for @BGRNDSTART/@BGRND/@BGRNDEND.
type Divs struct {
	divs     []string
	pos      int
	div_used bool
}

// new_divs takes the DIV names through which next will cycle.
func new_divs(names []string) *Divs {
	return &Divs{divs: names, pos: len(names) + 1}
}

// next fetches the next DIV name.
func (d *Divs) next() string {
	d.div_used = true
	d.pos = d.pos + 1
	if d.pos >= len(d.divs) {
		d.pos = 0
	}
	return d.divs[d.pos]
}

// State holds global state. The Ruby has a Singleton; here there is one
// package-level instance, state.
type State struct {
	divs *Divs
}

var state = &State{}

func (s *State) divs_start(names []string) error {
	if s.divs != nil {
		return errors.New("DIVs within DIVs")
	}
	s.divs = new_divs(names)
	return nil
}

func (s *State) divs_end() {
	s.divs = nil
}

func (s *State) divs_next() (string, error) {
	if s.divs == nil {
		return "", errors.New("@BGRND used without @BGRNDSTART")
	}
	return s.divs.next(), nil
}

func (s *State) divs_active() bool {
	if s.divs == nil {
		return false
	}
	return s.divs.div_used
}

// op_func is the signature of every handler (Ruby: func(stack, code)).
// stack holds the items between "@CMD{{" and "}}" and code is the command
// name (for @N1{{..}} the code is "N1"). The result replaces those items.
type op_func func(stack []Item, code string) ([]Item, error)

// op_table is what the Ruby does with send(op, ...): handler name to handler.
var op_table = map[string]op_func{
	"process_marker":            process_marker,
	"process_hiragana":          process_hiragana,
	"process_kanji":             process_kanji,
	"process_katakana":          process_katakana,
	"process_furigana":          process_furigana,
	"process_emphasis":          process_emphasis,
	"process_grammar_index":     process_grammar_index,
	"process_literal":           process_literal,
	"process_empty_code":        process_empty_code,
	"process_background_start":  process_background_start,
	"process_background_insert": process_background_insert,
	"process_background_end":    process_background_end,
	"process_radical":           process_radical,
	"process_optional_text":     process_optional_text,
	"process_formation":         process_formation,
	"process_NSV":               process_NSV,
}

// command_to_op is the Ruby $command_to_op: command name to handler name.
// Note that N, V and S commands followed by digits (and plain N, V and S) are
// caught earlier by nsv_re and sent to process_NSV, so the V1..V7 and S entries
// below are never used. They are kept to match the Ruby.
var command_to_op = map[string]string{
	"MK":     "process_marker",
	"HI":     "process_hiragana",
	"KJ":     "process_kanji",
	"KT":     "process_katakana",
	"FG":     "process_furigana",
	"EM":     "process_emphasis",
	"GRMIDX": "process_grammar_index",
	"LIT":    "process_literal",

	"masustem":    "process_empty_code",
	"V1":          "process_empty_code",
	"V2":          "process_empty_code",
	"V3":          "process_empty_code",
	"V4":          "process_empty_code",
	"V5":          "process_empty_code",
	"V6":          "process_empty_code",
	"V7":          "process_empty_code",
	"1D":          "process_empty_code",
	"5D":          "process_empty_code",
	"Nplace":      "process_empty_code",
	"S":           "process_empty_code",
	"Splain":      "process_empty_code",
	"Vplain":      "process_empty_code",
	"Vru":         "process_empty_code",
	"Vnai":        "process_empty_code",
	"Vnaide":      "process_empty_code",
	"Vnaistem":    "process_empty_code",
	"Vzu":         "process_empty_code",
	"Vnu":         "process_empty_code",
	"Vmasu":       "process_empty_code",
	"Vmasustem":   "process_empty_code",
	"Vte":         "process_empty_code",
	"Vde":         "process_empty_code",
	"Vteiru":      "process_empty_code",
	"Vdeiru":      "process_empty_code",
	"Vta":         "process_empty_code",
	"Vtara":       "process_empty_code",
	"Vba":         "process_empty_code",
	"Vyou":        "process_empty_code",
	"Vreru":       "process_empty_code",
	"Vrenai":      "process_empty_code",
	"Vrareru":     "process_empty_code",
	"Vsaseru":     "process_empty_code",
	"Vsasete":     "process_empty_code",
	"Vsaserareru": "process_empty_code",
	"NS":          "process_empty_code",
	"NPhr":        "process_empty_code",
	"VPhr":        "process_empty_code",
	"Ai":          "process_empty_code",
	"Aistem":      "process_empty_code",
	"Aku":         "process_empty_code",
	"Akute":       "process_empty_code",
	"Ana":         "process_empty_code",
	"Anastem":     "process_empty_code",
	"MIDDOT":      "process_empty_code",

	"BGRNDSTART": "process_background_start",
	"BGRND":      "process_background_insert",
	"BGRNDEND":   "process_background_end",

	"SHIME":     "process_empty_code",
	"JTILDE":    "process_empty_code",
	"JDOTS3":    "process_empty_code",
	"JDOTS6":    "process_empty_code",
	"KA":        "process_empty_code", // small ka
	"KE":        "process_empty_code", // small ke
	"KOME":      "process_empty_code",
	"JSTAR":     "process_empty_code",
	"TICK":      "process_empty_code",
	"QNTF":      "process_empty_code",
	"QW":        "process_empty_code",
	"CTR":       "process_empty_code",
	"ADV":       "process_empty_code",
	"PRT":       "process_empty_code",
	"RELC":      "process_empty_code",
	"RD":        "process_radical",
	"OPTTEXT":   "process_optional_text",
	"FORMATION": "process_formation",
	"HIMITSU":   "process_empty_code",
	"VERPEND":   "process_empty_code",
}

// process_at_commands expands every @command{{...}} in text and returns the result.
//
// Given:
//
//	some-text @HI{{hiragana @KJ{{kanji}} more-hiragana @KT{{katakana}} even-more-hiragana}} trailing-text
//
// the stack evolves like this (the Ruby has the full walk-through):
//   - "some-text" is output directly, because the stack is empty.
//   - "@HI{{" pushes an operation, then "hiragana " is pushed as Text.
//   - "@KJ{{" pushes an operation and "kanji" is pushed as Text.
//   - "}}" pops back to the @KJ operation and calls its handler. The result
//     (DoneText) goes back on the stack.
//   - and so on, until the "}}" that closes the @HI, whose handler then sees a
//     mixture of unprocessed Text (to be converted) and DoneText (left alone).
//
// A ProcessingError is not fatal: processing continues, but at the end the
// whole run fails. Any other error ends processing immediately.
func process_at_commands(text string, data_dir string, filename string, raise_exception_on_error bool) (string, error) {
	// The Ruby comments that global variables are bad, and hopes to remove this one.
	fail_on_error = raise_exception_on_error

	var processing_errors []error // Collect errors instead of exiting immediately

	// REF is special and must be processed before anything else.
	// Recursive REFs make no sense so do not cater for them.
	text, err := rubycompat.GsubFunc(ref_re, text, func(m []string) (string, error) {
		unchecked := (m[1] == "UCREF")
		ref := m[2]
		return transform_ref(ref, data_dir, unchecked)
	})
	if err != nil {
		return "", err
	}

	var stack []Item
	var answer strings.Builder

	to_handle := text
	if !opening_re.MatchString(to_handle) {
		// No command found: the text is output as it stands (even if it
		// contains a stray "}}").
		answer.WriteString(to_handle)
		to_handle = ""
	}

	for to_handle != "" {
		loc := token_re.FindStringIndex(to_handle)
		if loc == nil {
			// No match. This must be a sequence of trailing text that will never be processed
			answer.WriteString(to_handle)
			break
		}

		// Ruby: m.pre_match(), m[0] and m.post_match()
		text := to_handle[:loc[0]]
		current := to_handle[loc[0]:loc[1]]
		to_handle = to_handle[loc[1]:]

		// The optimisations from the Ruby: if the stack is empty, output the
		// text directly rather than stacking it.
		if len(stack) == 0 {
			answer.WriteString(text)
		} else {
			stack = append(stack, new_text(text))
		}

		if closing_re.MatchString(current) {
			// Build the mini stack by working backwards through the stack until
			// an operation is found.
			var mini_stack []Item
			var object Item
			for len(stack) > 0 {
				object = stack[len(stack)-1]
				stack = stack[:len(stack)-1]
				if !object.is_text() {
					break
				}
				mini_stack = append([]Item{object}, mini_stack...) // This element belongs _before_ the element just added
			}

			// Call the op processor - if there isn't one then this is a bug
			if object == nil {
				return "", fmt.Errorf("No object on the stack with current [%s%s] to handle [%s]", text, current, to_handle)
			}
			op := object.operation()
			if op == "" {
				return "", errors.New("Object has no operation")
			}
			handler, found := op_table[op]
			if !found {
				return "", fmt.Errorf("No handler named [%s]", op)
			}

			result, err := handler(mini_stack, object.code())
			if err != nil {
				var processing_error *ProcessingError
				if !errors.As(err, &processing_error) {
					fmt.Fprintln(os.Stderr, err)
					fmt.Fprintf(os.Stderr, "Fatal error processing <%s> near line: [%s]\n", op, first_line(to_handle))
					fmt.Fprintf(os.Stderr, "Fatal data: [%s\n]\n", first_runes(to_handle, 31))
					fmt.Fprintf(os.Stderr, "in source [%s]\n", filename)
					return "", err
				}
				fmt.Fprintf(os.Stderr, "Non-fatal error: %s\n", processing_error.message)
				processing_errors = append(processing_errors, err) // Store the error so we can decide what to do later
				result = []Item{new_done_text(processing_error.message)}
			}

			if len(stack) == 0 {
				output, err := puts_result(result)
				if err != nil {
					return "", err
				}
				answer.WriteString(output)
			} else {
				stack = append(stack, result...)
			}
		} else {
			// An opening token: "@COMMAND{{"
			m := command_re.FindStringSubmatch(current)
			if m == nil {
				return "", fmt.Errorf("Badly formed command: [%s]", current)
			}
			command := m[1]
			if nsv_re.MatchString(command) {
				stack = append(stack, new_operation("process_NSV", command))
			} else if op, found := command_to_op[command]; found {
				stack = append(stack, new_operation(op, command))
			} else {
				// The Ruby ignores an unknown command here (its comment says
				// "should be a raise"). Nothing is pushed, so the matching "}}"
				// will normally end in an error.
				debug_out(fmt.Sprintf("No OP found for [%s] in [%s]", command, current))
			}
		}
	}

	if len(stack) > 0 {
		dump_stack(stack)
		return "", errors.New("Non-empty stack")
	}

	if len(processing_errors) > 0 {
		return "", fmt.Errorf("\nEncountered %d errors during processing.", len(processing_errors))
	}

	return answer.String(), nil
}

// first_line returns the first line of s (Ruby: s.split(/\n|\r\n/)[0]).
func first_line(s string) string {
	if i := strings.Index(s, "\n"); i >= 0 {
		s = s[:i]
	}
	return strings.TrimSuffix(s, "\r")
}

// first_runes returns the first n characters of s (Ruby: s[0..n-1]).
func first_runes(s string, n int) string {
	runes := []rune(s)
	if len(runes) > n {
		runes = runes[:n]
	}
	return string(runes)
}

//+
// Utility functions
//-

// transform_ref substitutes one @REF{{}} (or @UCREF{{}}) statement. An unknown
// reference is not an error: it produces a visible "UNKNOWN REF" marker.
func transform_ref(text string, data_dir string, unchecked bool) (string, error) {
	res := ""
	ref, err := convert_ref(text, data_dir)
	if err != nil {
		return "", err
	}
	if ref == nil {
		res = "&lt;UNKNOWN REF [" + text + "]&gt;"
	} else {
		alt := ref.alternate
		has_alt := alt != ""
		if has_alt {
			// The space after the ">" is in the Ruby, and so in the output.
			res = "<span title=\"" + alt + "\"> "
		}
		if unchecked {
			res += jp_unicode(0x203B)
		}
		res += ref.text
		if has_alt {
			res += "</span>"
		}
	}
	return res, nil
}

// dump_stack is a debug function used to display the current state of the stack.
func dump_stack(orig_stack []Item) {
	for i := len(orig_stack) - 1; i >= 0; i-- {
		diagnostic_out(orig_stack[i].display())
	}
}

// mark_as_grammar returns the supplied text modified to be marked as a grammatical text.
func mark_as_grammar(text string) string {
	return `<span class="grammar">` + text + `</span>`
}

// puts_result concatenates all the text in a stack into a single string.
func puts_result(stack []Item) (string, error) {
	var result strings.Builder
	for _, x := range stack {
		if x.is_op() {
			return "", errors.New("Trying to output OP")
		}
		result.WriteString(x.text())
	}
	return result.String(), nil
}

// collapse_result concatenates all the text in a stack into a single DoneText.
func collapse_result(stack []Item) (*DoneText, error) {
	for _, x := range stack {
		if x.is_op() {
			return nil, errors.New("Found OP in result")
		}
	}
	text, err := puts_result(stack)
	if err != nil {
		return nil, err
	}
	return new_done_text(text), nil
}

// collapse_stack is collapse_result, with the DoneText returned as a one-element slice.
func collapse_stack(stack []Item) ([]Item, error) {
	done, err := collapse_result(stack)
	if err != nil {
		return nil, err
	}
	return []Item{done}, nil
}

//+
// Process functions.
//
// Each function conforms to the op_func API:
//
// func(stack, code)
//  stack - a slice of items to which this function should be applied in turn
//  code  - a string describing the command (e.g. for @N1{{..}} the string would be N1)
//
//  returns: a slice of items
//-

// process_hiragana processes all unprocessed text as hiragana.
func process_hiragana(stack []Item, unused string) ([]Item, error) {
	var result []Item
	for _, x := range stack {
		if x.is_processed() {
			result = append(result, x)
		} else {
			converted, err := convert_to_hiragana(x.text())
			if err != nil {
				return nil, err
			}
			result = append(result, new_done_text(converted))
		}
	}
	return collapse_stack(result)
}

// process_kanji processes all unprocessed text as kanji.
func process_kanji(stack []Item, unused string) ([]Item, error) {
	var result []Item
	for _, x := range stack {
		if x.is_processed() {
			result = append(result, x)
		} else {
			converted, err := convert_to_kanji(x.text(), fail_on_error)
			if err != nil {
				return nil, err
			}
			result = append(result, new_done_text(converted))
		}
	}
	return collapse_stack(result)
}

// process_radical processes all unprocessed text as radicals.
func process_radical(stack []Item, unused string) ([]Item, error) {
	var result []Item
	for _, x := range stack {
		if x.is_processed() {
			result = append(result, x)
		} else {
			result = append(result, new_done_text(convert_to_radical(x.text())))
		}
	}
	return collapse_stack(result)
}

// process_furigana processes a furigana. Everything up to the first ":" is the
// text to display and everything else is assumed to be the furigana (which is
// encoded as a title). All otherwise unprocessed text is assumed to be hiragana.
func process_furigana(stack []Item, unused string) ([]Item, error) {
	var display_result []Item
	var result []Item
	in_display := true
	for _, x := range stack {
		if x.is_processed() {
			result = append(result, x)
			continue
		}
		text := x.text()
		// If the first ":" is seen, switch from display to tooltip
		if colon := strings.Index(text, ":"); in_display && colon >= 0 {
			pre := text[:colon]
			post := text[colon+1:]
			pre_hiragana, err := convert_to_hiragana(pre)
			if err != nil {
				return nil, err
			}
			result = append(result, new_done_text(pre_hiragana))
			display_result = result
			post_hiragana, err := convert_to_hiragana(post)
			if err != nil {
				return nil, err
			}
			result = []Item{new_done_text(post_hiragana)}
			in_display = false
		} else {
			converted, err := convert_to_hiragana(text)
			if err != nil {
				return nil, err
			}
			result = append(result, new_done_text(converted))
		}
	}
	if in_display {
		dump_stack(result)
		return nil, errors.New("Failed to specify furigana in @FG")
	}
	tooltip, err := collapse_result(result)
	if err != nil {
		return nil, err
	}
	display, err := collapse_result(display_result)
	if err != nil {
		return nil, err
	}
	tip := "<span title=\"" + tooltip.text() + "\">" + display.text() + "</span>"
	return []Item{new_done_text(tip)}, nil
}

// process_katakana processes all unprocessed text as katakana.
func process_katakana(stack []Item, unused string) ([]Item, error) {
	var result []Item
	for _, x := range stack {
		if x.is_processed() {
			result = append(result, x)
		} else {
			converted, err := convert_to_katakana(x.text())
			if err != nil {
				return nil, err
			}
			result = append(result, new_done_text(converted))
		}
	}
	return collapse_stack(result)
}

// process_literal marks its contents as a literal translation. Unprocessed
// text is left as it is.
func process_literal(stack []Item, unused string) ([]Item, error) {
	result := []Item{new_done_text("(lit: ")}
	for _, x := range stack {
		if x.is_processed() {
			result = append(result, x)
		} else {
			result = append(result, new_done_text(x.text()))
		}
	}
	result = append(result, new_done_text(")"))
	return collapse_stack(result)
}

// process_optional_text marks its contents as "optional".
// The current implementation just underlines it for now.
func process_optional_text(stack []Item, unused string) ([]Item, error) {
	result := []Item{new_done_text("<u>")}
	for _, x := range stack {
		if x.is_processed() {
			result = append(result, x)
		} else {
			result = append(result, new_done_text(x.text()))
		}
	}
	result = append(result, new_done_text("</u>"))
	return collapse_stack(result)
}

// process_formation processes a formation.
// The current implementation reproduces the original text unchanged.
func process_formation(stack []Item, unused string) ([]Item, error) {
	var result []Item
	for _, x := range stack {
		if x.is_processed() {
			result = append(result, x)
		} else {
			result = append(result, new_done_text(x.text()))
		}
	}
	return collapse_stack(result)
}

// process_marker replaces @MK{{text}} with a marker made from the last item.
func process_marker(stack []Item, unused string) ([]Item, error) {
	if len(stack) == 0 {
		return nil, errors.New("@MK has no contents")
	}
	return []Item{new_done_text("[[MARKER:" + stack[len(stack)-1].text() + "]]")}, nil
}

// process_empty_code_helper transforms text from a command of the form @ABC{{}}.
func process_empty_code_helper(code string) (string, error) {
	switch code {
	case "masustem":
		return mark_as_grammar("<sub><del>" + hiragana_const("masu") + "</del></sub>"), nil
	case "V1":
		return "V<sub>1</sub>", nil
	case "V2":
		return "V<sub>2</sub>", nil
	case "V3":
		return "V<sub>3</sub>", nil
	case "V4":
		return "V<sub>4</sub>", nil
	case "V5":
		return "V<sub>5</sub>", nil
	case "V6":
		return "V<sub>" + hiragana_const("te") + "</sub>", nil
	case "V7":
		return "V<sub>" + hiragana_const("ta") + "</sub>", nil
	case "1D":
		return convert_to_kanji("ichi^dan", false)
	case "5D":
		return convert_to_kanji("go^dan", false)
	case "Nplace":
		return mark_as_grammar("N<sub>place</sub>"), nil
	case "S":
		return mark_as_grammar("S"), nil // sentence (either plain or polite)
	case "Splain":
		return mark_as_grammar("S<sub>plain</sub>"), nil // plain form sentence
	case "Vplain":
		return mark_as_grammar("V<sub>plain</sub>"), nil // plain form
	case "Vru":
		return mark_as_grammar("V" + hiragana_const("ru")), nil // dictionary form
	case "Vnai":
		return mark_as_grammar("V" + hiragana_const("nai")), nil // negative
	case "Vnaide":
		return mark_as_grammar("V" + hiragana_const("naide")), nil // negative-te-form
	case "Vnaistem":
		return mark_as_grammar("V<del>" + hiragana_const("nai") + "</del>"), nil // negative stem
	case "Vzu":
		return mark_as_grammar("V" + hiragana_const("zu")), nil // negative zu-form
	case "Vnu":
		return mark_as_grammar("V" + hiragana_const("nu")), nil // negative nu-form
	case "Vmasu":
		return mark_as_grammar("V" + hiragana_const("masu")), nil // masu form
	case "Vmasustem":
		return mark_as_grammar("V<del>" + hiragana_const("masu") + "</del>"), nil // masu stem
	case "Vte":
		return mark_as_grammar("V" + hiragana_const("te")), nil // te-form
	case "Vde":
		return mark_as_grammar("V" + hiragana_const("de")), nil // te-form for "mu"/"bu"
	case "Vta":
		return mark_as_grammar("V" + hiragana_const("ta")), nil // past
	case "Vtara":
		return mark_as_grammar("V" + hiragana_const("tara")), nil // ta-conditional
	case "Vteiru":
		return mark_as_grammar("V" + hiragana_const("teiru")), nil // te iru form
	case "Vdeiru":
		return mark_as_grammar("V" + hiragana_const("deiru")), nil // te iru form for "mu"/"bu"
	case "Vba":
		return mark_as_grammar("V" + hiragana_const("ba")), nil // ba (conditional)
	case "Vyou":
		return mark_as_grammar("V" + hiragana_const("you")), nil // volitional
	case "Vreru":
		return mark_as_grammar("V" + hiragana_const("reru")), nil // potential
	case "Vrenai":
		return mark_as_grammar("V" + hiragana_const("renai")), nil // negative potential
	case "Vrareru":
		return mark_as_grammar("V" + hiragana_const("rareru")), nil // passive
	case "Vsaseru":
		return mark_as_grammar("V" + hiragana_const("saseru")), nil // causative
	case "Vsasete":
		return mark_as_grammar("V" + hiragana_const("sasete")), nil // causative-te-form
	case "Vsaserareru":
		return mark_as_grammar("V" + hiragana_const("saserareru")), nil // causative-passive
	case "NS":
		return mark_as_grammar("N<del>" + hiragana_const("suru") + "</del>"), nil // noun-suru without suru
	case "NPhr":
		return mark_as_grammar("N-<em>phrase</em>"), nil // noun-phrase
	case "VPhr":
		return mark_as_grammar("V-<em>phrase</em>"), nil // verb-phrase
	case "Ai":
		return mark_as_grammar("A-" + hiragana_const("i")), nil // i-adjective
	case "Aistem":
		return mark_as_grammar("A-<del>" + hiragana_const("i") + "</del>"), nil // i-adjective stem
	case "Aku":
		return mark_as_grammar("A-" + hiragana_const("ku")), nil // i-adjective + ku
	case "Akute":
		return mark_as_grammar("A-" + hiragana_const("kute")), nil // i-adjective + kute
	case "Ana":
		return mark_as_grammar("A-" + hiragana_const("na")), nil // na-adjective
	case "Anastem":
		return mark_as_grammar("A-<del>" + hiragana_const("na") + "</del>"), nil // na-adjective stem
	case "MIDDOT":
		return jp_unicode(0x30fb), nil // katakana mid-dot
	case "SHIME":
		return jp_unicode(0x3006), nil // "shime"
	case "JTILDE":
		return jp_unicode(0x301c), nil // ~ (Japanese)
	case "JDOTS3":
		return jp_unicode(0x2026), nil // ...
	case "JDOTS6":
		return jp_unicode(0x2026) + jp_unicode(0x2026), nil // ... (twice)
	case "KA":
		return jp_unicode(0x30f5), nil // small ka
	case "KE":
		return jp_unicode(0x30f6), nil // small ke
	case "KOME":
		return jp_unicode(0x203b), nil // "rice symbol"
	case "JSTAR":
		return jp_unicode(0xff0a), nil // 5 point line-star
	case "TICK":
		return jp_unicode(0x2713), nil // tick symbol (check mark)
	case "QNTF":
		return "<em>quantifier</em>", nil
	case "QW":
		return "<em>interrogative</em>", nil // QW = question word = interrogative
	case "CTR":
		return "<em>counter</em>", nil
	case "ADV":
		return "<em>adverb</em>", nil
	case "PRT":
		return "<em>particle</em>", nil
	case "RELC":
		return "<em>relative-clause</em>", nil
	case "HIMITSU":
		return "<!-- DO_NOT_RELEASE -->", nil // marker indicating source not to be released
	case "VERPEND":
		return "<!-- UNVERIFIED -->", nil // marker indicating something that has not been verified by a native speaker or book
	}
	return "&lt;UNKNOWN @code [" + code + "]&gt;", nil
}

// process_empty_code processes a command of the form @ABC{{}}, i.e. one with
// no parameter. Anything between the brackets is ignored.
func process_empty_code(stack []Item, code string) ([]Item, error) {
	text, err := process_empty_code_helper(code)
	if err != nil {
		return nil, err
	}
	return []Item{new_done_text(text)}, nil
}

// process_NSV processes a command of the form @N123{{}}, @S123{{}}, @V123{{}}
func process_NSV(stack []Item, code string) ([]Item, error) {
	var contents []Item
	for _, x := range stack {
		if x.is_processed() {
			contents = append(contents, x)
		} else {
			contents = append(contents, new_done_text(x.text()))
		}
	}
	collapsed, err := collapse_result(contents)
	if err != nil {
		return nil, err
	}
	brackets := collapsed.text()
	str := code[0:1]
	sub := code[1:] // lose first character
	if code == "V6" {
		sub = hiragana_const("te") // TODO - just for comparison
	}
	if code == "V7" {
		sub = hiragana_const("ta") // TODO - just for comparison
	}
	if sub != "" {
		str += "<sub>" + sub + "</sub>"
	}
	if brackets != "" {
		str += "(" + brackets + ")"
	}
	if !v_digit_re.MatchString(code) { // TODO - just for comparison
		str = mark_as_grammar(str)
	}
	return []Item{new_done_text(str)}, nil
}

// process_emphasis adds emphasis to highlight a grammar point.
// Currently simply surrounds the parameter with <strong> and </strong>.
// The parameter is left alone and could be subject to further processing.
func process_emphasis(stack []Item, code string) ([]Item, error) {
	result := []Item{new_done_text("<strong>")}
	result = append(result, stack...)
	result = append(result, new_done_text("</strong>"))
	return result, nil
}

// process_grammar_index discards @GRMIDX{{...}}. (Normal JHTML processing does this.)
func process_grammar_index(stack []Item, code string) ([]Item, error) {
	return []Item{}, nil
}

// process_background_start handles @BGRNDSTART{{}}.
// Sets up the set of DIVs through which @BGRND{{}} will cycle.
func process_background_start(stack []Item, unused string) ([]Item, error) {
	var names []string
	for _, x := range stack {
		names = append(names, rubycompat.SplitRegexp(background_split_re, x.text())...)
	}
	if len(names) == 0 {
		names = []string{"LightGrey", "MistyRose"}
	}
	if err := state.divs_start(names); err != nil {
		return nil, err
	}
	return []Item{}, nil
}

// process_background_insert handles @BGRND{{}}.
// Closes a previous <DIV> (if one exists) and opens a new one.
func process_background_insert(stack []Item, unused string) ([]Item, error) {
	text := ""
	// If a DIV is in progress, close it off
	if state.divs_active() {
		text += insert_div_close()
	}

	// Start a new DIV
	next, err := state.divs_next()
	if err != nil {
		return nil, err
	}
	name := "style-" + next
	text += "<DIV class=\"" + name + "\"><p><br/></p>\n"
	return []Item{new_done_text(text)}, nil
}

// process_background_end handles @BGRNDEND{{}}.
func process_background_end(stack []Item, unused string) ([]Item, error) {
	// If a DIV is in progress, close it off
	text := ""
	if state.divs_active() {
		text += insert_div_close()
	}

	// Forget the existing DIVs
	state.divs_end()

	return []Item{new_done_text(text)}, nil
}

func insert_div_close() string {
	return "\n<p><br/></p></DIV>\n"
}
