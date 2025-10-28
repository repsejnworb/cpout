//go:build windows

package clipboard

import (
	"bytes"
	"fmt"
	"os/exec"
)

func Copy(s string) error {
	cmd := exec.Command("cmd", "/c", "clip")
	cmd.Stdin = bytes.NewBufferString(s)
	out, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("clip.exe: %w (%s)", err, string(out))
	}
	return nil
}
