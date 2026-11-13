package main

// Ported from scripts/ProcessingError.rb

// ProcessingError is a non-fatal processing problem. In strict mode the
// processing continues, but the run fails at the end.
type ProcessingError struct {
	message string
}

func (e *ProcessingError) Error() string {
	return e.message
}
