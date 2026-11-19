package main

// Ported from scripts/DebugSupport.rb

import (
	"fmt"
	"os"
)

// debug_out is for debugging messages. As in the Ruby, its body is commented
// out; uncomment it to see the messages on stderr.
func debug_out(text string) {
	//fmt.Fprintln(os.Stderr, text)
}

// diagnostic_out writes a message to stderr.
func diagnostic_out(text string) {
	fmt.Fprintln(os.Stderr, text)
}
