package run

import (
	"bufio"
	"bytes"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"strings"

	"github.com/repsejnworb/cpout/internal/clipboard"
)

type Options struct {
	StdoutOnly bool
	CopyOnly   bool
	IncludeCmd bool
	Markdown   bool
	FenceLang  string
	Truncate   int
}

func Run(argv []string, opt Options) (int, error) {
	if len(argv) == 0 {
		return 127, errors.New("no command provided")
	}

	header := ""
	if opt.IncludeCmd {
		header = headerLine(argv) + "\n"
	}

	out, code := runCapture(argv, opt.StdoutOnly)

	display := out
	if opt.Truncate > 0 {
		display = truncateLines(display, opt.Truncate)
	}

	// Print to terminal unless quiet
	if !opt.CopyOnly {
		if header != "" {
			fmt.Print(header)
		}
		fmt.Print(display)
		if !strings.HasSuffix(display, "\n") {
			fmt.Print("\n")
		}
	}

	clip := header + display
	if opt.Markdown {
		clip = wrapFenced(clip, opt.FenceLang)
	}

	if err := clipboard.Copy(clip); err != nil {
		// degrade gracefully
		if !opt.CopyOnly {
			fmt.Fprintf(os.Stderr, "cpout: clipboard error: %v\n", err)
		}
	}

	return code, nil
}

func runCapture(argv []string, stdoutOnly bool) (string, int) {
	cmd := exec.Command(argv[0], argv[1:]...)
	var buf bytes.Buffer
	cmd.Stdout = &buf
	if stdoutOnly {
		cmd.Stderr = nil
	} else {
		cmd.Stderr = &buf
	}
	err := cmd.Run()
	return buf.String(), exitCode(err)
}

func exitCode(err error) int {
	if err == nil {
		return 0
	}
	var ee *exec.ExitError
	if errors.As(err, &ee) {
		// UNIX-like
		type exitStatus interface{ ExitStatus() int }
		if s, ok := ee.Sys().(exitStatus); ok {
			return s.ExitStatus()
		}
	}
	// Windows may not implement ExitStatus(), fall back
	return 1
}

func truncateLines(s string, n int) string {
	if n <= 0 {
		return s
	}
	var b strings.Builder
	sc := bufio.NewScanner(strings.NewReader(s))
	lines := 0
	for sc.Scan() {
		if lines >= n {
			b.WriteString("… (truncated)")
			break
		}
		if lines > 0 {
			b.WriteByte('\n')
		}
		b.WriteString(sc.Text())
		lines++
	}
	return b.String()
}

func wrapFenced(content, lang string) string {
	open := "```"
	if lang != "" {
		open += lang
	}
	return open + "\n" + content + "\n```"
}

func headerLine(argv []string) string {
	// Simple shell-friendly quoting for aesthetics.
	parts := make([]string, 0, len(argv))
	for _, a := range argv {
		parts = append(parts, shellQuote(a))
	}
	prompt := "❯ "
	if runtime.GOOS == "windows" {
		prompt = ">" // keep it clean on Windows
	}
	return prompt + strings.Join(parts, " ")
}

func shellQuote(s string) string {
	if s == "" {
		return "''"
	}
	if strings.ContainsAny(s, " \t\n\"'`$\\!&*()[]{}|;<>?") {
		return "'" + strings.ReplaceAll(s, "'", `'\''`) + "'"
	}
	return s
}
