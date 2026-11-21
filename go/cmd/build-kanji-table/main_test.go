package main

// Tests of the generator against the Ruby generator (scripts/build-kanji-ruby.rb).
//
// Each directory in testdata/cases is one case:
//
//	kanji.data     the data file to build a table from (required)
//	fail           if present, both generators must fail, and their stderr must contain
//	               the text in this file
//	expect-stderr  (cases that succeed) text that the warnings on stderr must contain.
//	               This makes sure that a case really triggers what it is meant to test.
//
// The Go generator is always checked against these. If Ruby is installed, the
// Ruby generator is run on the same file too, and the two must agree: the same
// keys and code points in the table, and identical warnings on stderr.
//
// The Go generator runs as a child process (this test binary started again, as
// in the japanese-to-codes tests) because main() writes to stdout and exits.

import (
	"bytes"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"testing"
)

const run_as_program = "BUILD_KANJI_TABLE_RUN_AS_PROGRAM"

func TestMain(m *testing.M) {
	if os.Getenv(run_as_program) == "1" {
		main()
		os.Exit(0)
	}
	os.Exit(m.Run())
}

// A table entry in the Ruby generator's output:     :"one" => [1, 19968, [...
var ruby_entry_re = regexp.MustCompile(`^\s+:"(.*)" => \[\d+, (\d+),`)

// A table entry in this generator's output:         {"one", 19968},
var go_entry_re = regexp.MustCompile(`^\t\{("(?:[^"\\]|\\.)*"), (\d+)\},$`)

func parse_ruby_table(output string) (map[string]int, error) {
	table := map[string]int{}
	for _, line := range strings.Split(output, "\n") {
		m := ruby_entry_re.FindStringSubmatch(line)
		if m == nil {
			continue
		}
		code, _ := strconv.Atoi(m[2])
		if _, duplicate := table[m[1]]; duplicate {
			return nil, fmt.Errorf("duplicate key %q", m[1])
		}
		table[m[1]] = code
	}
	return table, nil
}

func parse_go_table(output string) (map[string]int, error) {
	table := map[string]int{}
	for _, line := range strings.Split(output, "\n") {
		m := go_entry_re.FindStringSubmatch(line)
		if m == nil {
			continue
		}
		key, err := strconv.Unquote(m[1])
		if err != nil {
			return nil, err
		}
		code, _ := strconv.Atoi(m[2])
		if _, duplicate := table[key]; duplicate {
			return nil, fmt.Errorf("duplicate key %q", key)
		}
		table[key] = code
	}
	return table, nil
}

// table_differences lists the entries on which two tables disagree.
func table_differences(want map[string]int, got map[string]int) []string {
	var diffs []string
	for key, code := range want {
		if g, found := got[key]; !found {
			diffs = append(diffs, fmt.Sprintf("only in Ruby: %q => %d", key, code))
		} else if g != code {
			diffs = append(diffs, fmt.Sprintf("%q: Ruby has %d, Go has %d", key, code, g))
		}
	}
	for key, code := range got {
		if _, found := want[key]; !found {
			diffs = append(diffs, fmt.Sprintf("only in Go: %q => %d", key, code))
		}
	}
	sort.Strings(diffs)
	return diffs
}

type run_result struct {
	stdout string
	stderr string
	failed bool
}

func run_command(t *testing.T, cmd *exec.Cmd) run_result {
	t.Helper()
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	err := cmd.Run()
	var exit_error *exec.ExitError
	if err != nil && !errors.As(err, &exit_error) {
		t.Fatalf("could not run %v: %v", cmd.Args, err)
	}
	return run_result{stdout: stdout.String(), stderr: stderr.String(), failed: err != nil}
}

func read_optional(t *testing.T, name string) (string, bool) {
	t.Helper()
	text, err := os.ReadFile(name)
	if os.IsNotExist(err) {
		return "", false
	}
	if err != nil {
		t.Fatal(err)
	}
	return string(text), true
}

// find_ruby returns the ruby program and the Ruby generator script, or "" if
// either is missing, in which case the comparison with the Ruby is skipped.
func find_ruby() (string, string) {
	ruby, err := exec.LookPath("ruby")
	if err != nil {
		return "", ""
	}
	script, err := filepath.Abs(filepath.Join("..", "..", "..", "scripts", "build-kanji-ruby.rb"))
	if err != nil {
		return "", ""
	}
	if _, err := os.Stat(script); err != nil {
		return "", ""
	}
	return ruby, script
}

func TestGenerator(t *testing.T) {
	fixtures, err := filepath.Glob(filepath.Join("testdata", "cases", "*", "kanji.data"))
	if err != nil {
		t.Fatal(err)
	}
	if len(fixtures) == 0 {
		t.Fatal("no test cases found in testdata/cases")
	}

	ruby, script := find_ruby()
	if ruby == "" {
		t.Log("ruby or scripts/build-kanji-ruby.rb not found: the Ruby generator is not being compared")
	}

	for _, fixture := range fixtures {
		dir := filepath.Dir(fixture)
		t.Run(filepath.Base(dir), func(t *testing.T) {
			run_case(t, dir, ruby, script)
		})
	}
}

func run_case(t *testing.T, dir string, ruby string, script string) {
	fixture, err := filepath.Abs(filepath.Join(dir, "kanji.data"))
	if err != nil {
		t.Fatal(err)
	}

	exe, err := os.Executable()
	if err != nil {
		t.Fatal(err)
	}
	go_cmd := exec.Command(exe, fixture)
	go_cmd.Env = append(os.Environ(), run_as_program+"=1")
	got := run_command(t, go_cmd)

	// The Ruby generator reads data/kanji.data from its working directory.
	var want run_result
	if ruby != "" {
		work := t.TempDir()
		if err := os.MkdirAll(filepath.Join(work, "data"), 0o755); err != nil {
			t.Fatal(err)
		}
		contents, err := os.ReadFile(fixture)
		if err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(filepath.Join(work, "data", "kanji.data"), contents, 0o644); err != nil {
			t.Fatal(err)
		}
		ruby_cmd := exec.Command(ruby, "-w", "-Eutf-8", script)
		ruby_cmd.Dir = work
		want = run_command(t, ruby_cmd)
	}

	// Cases that must fail, in both generators
	if text, expect_fail := read_optional(t, filepath.Join(dir, "fail")); expect_fail {
		fragment := strings.TrimSpace(text)
		if !got.failed {
			t.Errorf("Go: expected the generator to fail, but it succeeded")
		} else if !strings.Contains(got.stderr, fragment) {
			t.Errorf("Go: stderr does not contain %q; stderr was:\n%s", fragment, got.stderr)
		}
		if ruby != "" {
			if !want.failed {
				t.Errorf("Ruby: expected the generator to fail, but it succeeded")
			} else if !strings.Contains(want.stderr, fragment) {
				t.Errorf("Ruby: stderr does not contain %q; stderr was:\n%s", fragment, want.stderr)
			}
		}
		return
	}

	if got.failed {
		t.Fatalf("Go: the generator failed; stderr was:\n%s", got.stderr)
	}
	go_table, err := parse_go_table(got.stdout)
	if err != nil {
		t.Fatalf("Go: could not read the generated table: %v", err)
	}
	if len(go_table) == 0 {
		t.Error("Go: the generated table is empty (a mistake in the case?)")
	}
	if text, ok := read_optional(t, filepath.Join(dir, "expect-stderr")); ok {
		fragment := strings.TrimSpace(text)
		if !strings.Contains(got.stderr, fragment) {
			t.Errorf("Go: stderr does not contain %q; stderr was:\n%s", fragment, got.stderr)
		}
	}

	if ruby == "" {
		return
	}
	if want.failed {
		t.Fatalf("Ruby: the generator failed; stderr was:\n%s", want.stderr)
	}
	ruby_table, err := parse_ruby_table(want.stdout)
	if err != nil {
		t.Fatalf("Ruby: could not read the generated table: %v", err)
	}
	if diffs := table_differences(ruby_table, go_table); len(diffs) > 0 {
		t.Errorf("the tables differ:\n  %s", strings.Join(diffs, "\n  "))
	}
	if want.stderr != got.stderr {
		t.Errorf("stderr differs.\n--- Ruby:\n%s--- Go:\n%s", want.stderr, got.stderr)
	}
}
