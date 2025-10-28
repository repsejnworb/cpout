package cmd

import (
	"fmt"
	"os"
	"strings"

	"github.com/repsejnworb/cpout/internal/run"
	"github.com/repsejnworb/cpout/internal/version"
	"github.com/spf13/cobra"
)

var (
	flagStdoutOnly bool
	flagCopyOnly   bool
	flagIncludeCmd bool
	flagNoCmd      bool
	flagMarkdown   bool
	flagFenceLang  string
	flagTruncate   int
)

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		os.Exit(1)
	}
}

var rootCmd = &cobra.Command{
	Use:   "cpout [flags] -- <command> [args...]",
	Short: "Run a command, print its output, and copy it to the clipboard",
	Long: `cpout runs a command, prints its output, and copies it to the clipboard.
By default it merges stdout+stderr and includes a "❯ cmd args" header.`,
	Version: version.String(),
	Args:    cobra.ArbitraryArgs,
	RunE: func(cmd *cobra.Command, args []string) error {
		// Accepts both `cpout echo hej` and `cpout -- echo hej`
		if len(args) == 0 {
			return fmt.Errorf("missing command. Try: cpout -h")
		}

		includeCmd := flagIncludeCmd && !flagNoCmd
		opts := run.Options{
			StdoutOnly: flagStdoutOnly,
			CopyOnly:   flagCopyOnly,
			IncludeCmd: includeCmd,
			Markdown:   flagMarkdown || flagFenceLang != "",
			FenceLang:  flagFenceLang,
			Truncate:   flagTruncate,
		}

		code, err := run.Run(args, opts)
		// Preserve underlying command's exit code
		if err != nil {
			// only show a friendly message; the printed/clipboard output is already handled
			if !opts.CopyOnly {
				fmt.Fprintf(os.Stderr, "cpout: %v\n", err)
			}
		}
		os.Exit(code)
		return nil
	},
}

func init() {
	// Flags
	rootCmd.Flags().BoolVarP(&flagStdoutOnly, "stdout", "S", false, "stdout only (exclude stderr)")
	rootCmd.Flags().BoolVarP(&flagCopyOnly, "quiet", "q", false, "copy only (no terminal print)")
	rootCmd.Flags().BoolVarP(&flagIncludeCmd, "cmd", "c", true, "include the command header (default ON)")
	rootCmd.Flags().BoolVar(&flagNoCmd, "no-cmd", false, "do NOT include the command header")
	rootCmd.Flags().BoolVarP(&flagMarkdown, "markdown", "m", false, "copy as fenced code block (no language)")
	rootCmd.Flags().StringVarP(&flagFenceLang, "lang", "M", "", "fenced code block with language (e.g., bash)")
	rootCmd.Flags().IntVarP(&flagTruncate, "truncate", "t", 0, "truncate output to first N lines")

	// Bash/Zsh/Fish/PowerShell completions
	rootCmd.AddCommand(completionCmd)
}

var completionCmd = &cobra.Command{
	Use:       "completion [bash|zsh|fish|powershell]",
	Short:     "Generate shell completion",
	ValidArgs: []string{"bash", "zsh", "fish", "powershell"},
	Args:      cobra.MatchAll(cobra.ExactArgs(1), cobra.OnlyValidArgs),
	RunE: func(cmd *cobra.Command, args []string) error {
		switch strings.ToLower(args[0]) {
		case "bash":
			return rootCmd.GenBashCompletion(os.Stdout)
		case "zsh":
			return rootCmd.GenZshCompletion(os.Stdout)
		case "fish":
			return rootCmd.GenFishCompletion(os.Stdout, true)
		case "powershell":
			return rootCmd.GenPowerShellCompletionWithDesc(os.Stdout)
		default:
			return fmt.Errorf("unsupported shell: %s", args[0])
		}
	},
}
