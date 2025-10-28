//go:build darwin

package clipboard

import (
	"bytes"
	"fmt"
	"os/exec"
)

func Copy(s string) error {
	cmd := exec.Command("pbcopy")
	cmd.Stdin = bytes.NewBufferString(s)
	out, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("pbcopy: %w (%s)", err, string(out))
	}
	return nil
}
