# cpout — copy process output to clipboard (Oh My Zsh plugin)

Run a command, print its output, **and** copy it to the clipboard in one go.  
By default `cpout`:
- prints to terminal,
- copies to clipboard,
- and includes a `❯ command args` header.

> Requires macOS `pbcopy`. (Linux/Wayland support via `xclip`/`xsel`/`wl-copy` could be added later.)

---

## Install (Oh My Zsh)

```sh
git clone https://github.com/repsejnworb/cpout ~/.oh-my-zsh/custom/plugins/cpout
```

Enable in `~/.zshrc`:

```zsh
plugins=(... cpout ...)
source ~/.zshrc
```

Update:

```sh
(cd ~/.oh-my-zsh/custom/plugins/cpout && git pull)
```

---

## Usage

```sh
cpout [flags] <command> [args...]
```

### Flags

- `-S` stdout only (exclude stderr)  
- `-q` copy only (no terminal print)  
- `-c` include the command header (default; kept for compatibility)  
- `-N`, `--no-cmd` do **not** include the command header  
- `-m` copy as fenced code block (no language)  
- `-M <lang>` copy as fenced code block with language (e.g., `-M bash`)  
- `-t <lines>` truncate output to first N lines (printed + copied)  
- `-h` help  

### Examples

```sh
cpout echo hej
cpout -N echo hej                   # no header
cpout -S ls -la                     # stdout only
cpout -q cue vet schema.cue         # copy only, combined output
cpout -m cue vet schema.cue         # clipboard wrapped in ```
cpout -M bash cue vet schema.cue    # clipboard wrapped in ```bash
cpout -t 50 tail -n 1000 big.log    # keep first 50 lines
```

---

## Completion

Zsh completion is included and auto-loaded via `#compdef cpout` when the plugin is enabled.  
It reads the same internal flag spec used by the plugin, so flags stay in sync.

If you don’t want completion, remove `_cpout` from your local copy.

---

## Project layout

```
cpout/
├─ cpout.plugin.zsh   # main plugin (function + DRY flag spec)
└─ _cpout             # zsh completion (reads the same flag spec)
```

---

## Notes

- Exit status: `cpout` returns the exit code of the wrapped command.  
- Truncation (`-t`) affects both printed and copied output and appends `… (truncated)` when applicable.  
- Fencing (`-m`/`-M`) affects **clipboard** only; terminal output remains plain text.  

PRs for Linux/Wayland clipboard support are welcome.
