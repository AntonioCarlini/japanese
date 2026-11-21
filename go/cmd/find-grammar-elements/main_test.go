package main

import "testing"

func TestHtmlNameFor(t *testing.T) {
	tests := []struct{ in, want string }{
		{"grammar-zehi.jhtml", "grammar-zehi.html"},
		{"dir/a.jhtml", "dir/a.html"},
		{"a.txt", "a.txt"},
		{"a.jhtml.bak", "a.jhtml.bak"},
		// The Ruby's /.jhtml$/ has an unescaped dot, so any character will do.
		{"xjhtml", ".html"},
	}
	for _, tt := range tests {
		if got := html_name_for(tt.in); got != tt.want {
			t.Errorf("html_name_for(%q) = %q, want %q", tt.in, got, tt.want)
		}
	}
}

func TestFindGrammarElements(t *testing.T) {
	tests := []struct {
		name string
		text string
		want string
	}{
		{"no entries", "plain text", ""},
		{"one entry", "x @GRMIDX{{abc}} y", "a.html: abc\n"},
		{"nested commands",
			`x @GRMIDX{{index="@HI{{zehi}}" grammar="@HI{{zehi}}"}} y`,
			"a.html: index=\"@HI{{zehi}}\" grammar=\"@HI{{zehi}}\"\n"},
		{"two entries", "@GRMIDX{{a}}\n@GRMIDX{{b}}", "a.html: a\na.html: b\n"},
		{"empty entry", "@GRMIDX{{}}", "a.html: \n"},
		{"any case", "@grmidx{{x}}", "a.html: x\n"},
		{"contents end with a newline", "@GRMIDX{{a\n}}", "a.html: a\n"}, // puts adds no second newline
		// The Ruby mixes byte positions and character indices, so with a
		// non-ASCII character before the entry it picks out the wrong text.
		// This is kept so that the output stays the same. (See ruby_char_range.)
		{"non-ASCII before the entry", "日本 @GRMIDX{{ab}}", "a.html: \n"},
	}
	for _, tt := range tests {
		got, err := find_grammar_elements("a.jhtml", tt.text)
		if err != nil {
			t.Errorf("%s: unexpected error %v", tt.name, err)
		} else if got != tt.want {
			t.Errorf("%s: got %q, want %q", tt.name, got, tt.want)
		}
	}
}

func TestFindGrammarElementsUnclosed(t *testing.T) {
	for _, text := range []string{"@GRMIDX{{abc", "@GRMIDX{{a{{b}}"} {
		if _, err := find_grammar_elements("a.jhtml", text); err == nil {
			t.Errorf("%q: expected an error", text)
		}
	}
}
