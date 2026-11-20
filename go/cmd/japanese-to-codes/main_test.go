package main

// Golden-file tests. Each directory in testdata/cases is one test case, run the
// way make runs the program: a .jhtml file in, HTML on stdout and any messages
// on stderr. See testdata/README.md.
//
// The program under test is this very package: TestMain starts the test binary
// again as japanese-to-codes. Every case therefore runs in a fresh process, so
// the package-level state (state, ref_data, fail_on_error, rd_instance) never
// leaks from one case to the next.

import (
	"bytes"
	"errors"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

// run_as_program is set in the environment of the child processes, which then
// behave as japanese-to-codes instead of running the tests.
const run_as_program = "JAPANESE_TO_CODES_RUN_AS_PROGRAM"

var update = flag.Bool("update", false,
	"rewrite expected.html and expected.stderr from this program's output "+
		"(normally they are generated from the Ruby, by testdata/regenerate-golden.sh)")

func TestMain(m *testing.M) {
	if os.Getenv(run_as_program) == "1" {
		main()
		os.Exit(0)
	}
	os.Exit(m.Run())
}

func TestGolden(t *testing.T) {
	inputs, err := filepath.Glob(filepath.Join("testdata", "cases", "*", "input.jhtml"))
	if err != nil {
		t.Fatal(err)
	}
	if len(inputs) == 0 {
		t.Fatal("no test cases found in testdata/cases")
	}
	for _, input := range inputs {
		dir := filepath.Dir(input)
		t.Run(filepath.Base(dir), func(t *testing.T) {
			run_case(t, dir)
		})
	}
}

// run_case runs one test case directory:
//
//	input.jhtml      the file to convert (required)
//	args             extra command line arguments, e.g. --strict-fail-on-error (optional)
//	expected.html    what must be written to stdout
//	expected.stderr  what must be written to stderr (if absent, stderr must be empty)
//	fail             if present, the program must exit with an error and its
//	                 stderr must contain the text in this file (stdout is not checked)
func run_case(t *testing.T, dir string) {
	exe, err := os.Executable()
	if err != nil {
		t.Fatal(err)
	}

	// --data and --include are relative to this package's directory, which is
	// where "go test" runs the tests.
	args := []string{
		"--data=" + filepath.Join("testdata", "data"),
		"--include=" + filepath.Join("testdata", "include"),
	}
	if text, ok := read_optional(t, filepath.Join(dir, "args")); ok {
		args = append(args, strings.Fields(text)...)
	}
	args = append(args, filepath.Join(dir, "input.jhtml"))

	cmd := exec.Command(exe, args...)
	cmd.Env = append(os.Environ(), run_as_program+"=1")
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	err = cmd.Run()

	// A non-zero exit status is an *exec.ExitError; anything else means the
	// program could not even be started.
	var exit_error *exec.ExitError
	if err != nil && !errors.As(err, &exit_error) {
		t.Fatalf("could not run the program: %v", err)
	}

	// A case that is expected to fail only has to fail, with the right message.
	if fragment, ok := read_optional(t, filepath.Join(dir, "fail")); ok {
		if err == nil {
			t.Fatalf("expected the program to fail, but it succeeded; stdout was:\n%s", stdout.String())
		}
		want := strings.TrimSpace(fragment)
		if want != "" && !strings.Contains(stderr.String(), want) {
			t.Errorf("stderr does not contain %q; stderr was:\n%s", want, stderr.String())
		}
		return
	}

	if err != nil {
		t.Fatalf("the program failed: %v\nstderr was:\n%s", err, stderr.String())
	}
	compare(t, filepath.Join(dir, "expected.html"), stdout.String())
	compare(t, filepath.Join(dir, "expected.stderr"), stderr.String())
}

// compare checks got against the contents of the expected file. A missing
// expected file means "nothing" (so a case without expected.stderr must not
// write to stderr). With -update the file is rewritten instead.
func compare(t *testing.T, name string, got string) {
	t.Helper()

	if *update {
		if got == "" && strings.HasSuffix(name, ".stderr") {
			os.Remove(name)
		} else if err := os.WriteFile(name, []byte(got), 0o644); err != nil {
			t.Fatal(err)
		}
		return
	}

	want, err := os.ReadFile(name)
	if err != nil && !os.IsNotExist(err) {
		t.Fatal(err)
	}
	if string(want) != got {
		t.Errorf("%s differs: %s", filepath.Base(name), first_difference(string(want), got))
	}
}

// first_difference describes where two texts first differ.
func first_difference(want string, got string) string {
	want_lines := strings.Split(want, "\n")
	got_lines := strings.Split(got, "\n")
	for i := 0; i < len(want_lines) || i < len(got_lines); i++ {
		var w, g string
		if i < len(want_lines) {
			w = want_lines[i]
		}
		if i < len(got_lines) {
			g = got_lines[i]
		}
		if w != g {
			return fmt.Sprintf("first difference at line %d:\n  want: %q\n  got:  %q", i+1, w, g)
		}
	}
	return "the texts are the same"
}

// read_optional returns the contents of a file, and false if it does not exist.
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
