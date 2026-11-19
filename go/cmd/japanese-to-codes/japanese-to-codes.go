// japanese-to-codes converts a .jhtml file into HTML, writing the result to
// stdout. It is the Go port of scripts/japanese-to-codes.rb.
//
// Usage: japanese-to-codes FILE.jhtml [--data=DIR] [--include=DIR] [--strict-fail-on-error]
//
// The options may come before or after the file name (as GetoptLong allows).
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
	include_re = regexp.MustCompile(`@include\{\{"([^}]+)"\}\}`)
	v5_re      = regexp.MustCompile(`@V5\{\{([^}]+)\}\}`)
	jhtml_re   = regexp.MustCompile(`\.jhtml$`)
)

// long_option describes one command line option (Ruby: the GetoptLong table).
type long_option struct {
	name      string
	short     byte
	takes_arg bool
}

var long_options = []long_option{
	{"data", 'd', true},
	{"include", 'i', true},
	{"strict-fail-on-error", 's', false},
}

// getopt_long is a small stand-in for Ruby's GetoptLong with its default
// "permute" ordering: options and other arguments may be mixed. It accepts
// --name=value, --name value, unambiguous abbreviations of long names, -x value,
// -xvalue and "--" to end the options. It returns the option values and the
// remaining (non-option) arguments.
func getopt_long(args []string) (data_dir string, include_dir string, strict_fail_on_error bool, rest []string, err error) {
	apply := func(name string, value string) {
		switch name {
		case "data":
			data_dir = value
		case "include":
			include_dir = value
		case "strict-fail-on-error":
			strict_fail_on_error = true
		}
	}

	for i := 0; i < len(args); i++ {
		arg := args[i]
		switch {
		case arg == "--":
			rest = append(rest, args[i+1:]...)
			return

		case strings.HasPrefix(arg, "--"):
			name := arg[2:]
			value := ""
			has_value := false
			if eq := strings.Index(name, "="); eq >= 0 {
				value = name[eq+1:]
				name = name[:eq]
				has_value = true
			}

			// Find the option, allowing an unambiguous abbreviation.
			var matches []long_option
			for _, o := range long_options {
				if o.name == name {
					matches = []long_option{o}
					break
				}
				if strings.HasPrefix(o.name, name) {
					matches = append(matches, o)
				}
			}
			if len(matches) == 0 {
				err = fmt.Errorf("unrecognized option `--%s'", name)
				return
			}
			if len(matches) > 1 {
				err = fmt.Errorf("option `--%s' is ambiguous", name)
				return
			}
			o := matches[0]

			if o.takes_arg && !has_value {
				if i+1 >= len(args) {
					err = fmt.Errorf("option `--%s' requires an argument", o.name)
					return
				}
				i++
				value = args[i]
			} else if !o.takes_arg && has_value {
				err = fmt.Errorf("option `--%s' doesn't allow an argument", o.name)
				return
			}
			apply(o.name, value)

		case len(arg) > 1 && arg[0] == '-':
			// One or more short options, e.g. -s or -d DIR or -dDIR
			for j := 1; j < len(arg); j++ {
				var o *long_option
				for n := range long_options {
					if long_options[n].short == arg[j] {
						o = &long_options[n]
					}
				}
				if o == nil {
					err = fmt.Errorf("invalid option -- %c", arg[j])
					return
				}
				if !o.takes_arg {
					apply(o.name, "")
					continue
				}
				value := arg[j+1:]
				if value == "" {
					if i+1 >= len(args) {
						err = fmt.Errorf("option requires an argument -- %c", arg[j])
						return
					}
					i++
					value = args[i]
				}
				apply(o.name, value)
				break
			}

		default:
			rest = append(rest, arg)
		}
	}
	return
}

// handle_cli parses the command line and returns the file to process, the data
// and include directories and the strict flag.
func handle_cli() (file string, data_dir string, include_dir string, strict_fail_on_error bool, err error) {
	args := os.Args[1:]
	if len(args) == 0 {
		fmt.Printf("Usage: %s text-to-translate\n", filepath.Base(os.Args[0]))
		os.Exit(0)
	}

	data_dir, include_dir, strict_fail_on_error, argv, err := getopt_long(args)
	if err != nil {
		return "", "", "", false, err
	}

	if len(argv) == 0 {
		return "", "", "", false, errors.New("no input file specified")
	}
	file = argv[0]
	argv = argv[1:]

	// The output name is never used for anything else: the output goes to
	// stdout. It is only checked to be different from the input.
	var output string
	if len(argv) == 0 {
		output = jhtml_re.ReplaceAllString(file, ".html")
	} else {
		output = argv[0]
	}

	if output == file {
		return "", "", "", false, errors.New("Input file unsuitable")
	}

	return file, data_dir, include_dir, strict_fail_on_error, nil
}

// puts writes s to stdout and, like Ruby's puts, adds a newline unless s
// already ends with one.
func puts(s string) {
	if !strings.HasSuffix(s, "\n") {
		s += "\n"
	}
	fmt.Fprint(os.Stdout, s)
}

func processing() error {
	file, data_dir, include_dir, strict_fail_on_error, err := handle_cli()
	if err != nil {
		return err
	}

	if data_dir != "" && !strings.HasSuffix(data_dir, "/") {
		data_dir += "/"
	}
	if include_dir != "" && !strings.HasSuffix(include_dir, "/") {
		include_dir += "/"
	}

	// Read the file and process @include statements
	contents, err := os.ReadFile(file)
	if err != nil {
		return err
	}
	file_text := string(contents)

	for passes := 1; ; passes++ {
		include_seen := false
		file_text, err = rubycompat.GsubFunc(include_re, file_text, func(m []string) (string, error) {
			include_seen = true
			included, err := os.ReadFile(include_dir + m[1])
			if err != nil {
				return "", err
			}
			return string(included), nil
		})
		if err != nil {
			return err
		}
		if !include_seen {
			break
		}
		if passes >= max_include_passes {
			return errors.New("@include nested too deeply (does a file include itself?)")
		}
	}

	// Special case V5{{text}} for now to match the original operation
	file_text, err = rubycompat.GsubFunc(v5_re, file_text, func(m []string) (string, error) {
		text := m[1]
		str := "V<sub>5</sub>"
		if text != "" {
			str += "(" + text + ")"
		}
		return str, nil
	})
	if err != nil {
		return err
	}

	output, err := process_at_commands(file_text, data_dir, file, strict_fail_on_error)
	if err != nil {
		return err
	}
	puts(output)
	return nil
}

func main() {
	// The only panic in this program is hiragana_const, which signals a
	// programming mistake rather than bad input.
	defer func() {
		if r := recover(); r != nil {
			fmt.Fprintf(os.Stderr, "internal error: %v\n", r)
			os.Exit(1)
		}
	}()

	if err := processing(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
