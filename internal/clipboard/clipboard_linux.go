//go:build linux

package clipboard

import (
	"bytes"
	"fmt"
	"os/exec"
)

func Copy(s string) error {
	// Try xclip first
	if _, err := exec.LookPath("xclip"); err == nil {
		cmd := exec.Command("xclip", "-selection", "clipboard")
		cmd.Stdin = bytes.NewBufferString(s)
		if out, err := cmd.CombinedOutput(); err == nil {
			return nil
		} else {
			return fmt.Errorf("xclip: %w (%s)", err, string(out))
		}
	}
	// Fallback to xsel
	if _, err := exec.LookPath("xsel"); err == nil {
		cmd := exec.Command("xsel", "--clipboard", "--input")
		cmd.Stdin = bytes.NewBufferString(s)
		if out, err := cmd.CombinedOutput(); err == nil {
			return nil
		} else {
			return fmt.Errorf("xsel: %w (%s)", err, string(out))
		}
	}
	return fmt.Errorf("no clipboard tool found (install xclip or xsel)")
}
