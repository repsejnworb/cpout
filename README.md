# cpout (Oh My Zsh plugin)

Run a command, print its output, and copy it to the clipboard in one go.  
Defaults: includes the `❯ command` header, prints to terminal, and copies to clipboard.

## Flags
- `-S` stdout only (exclude stderr)
- `-q` copy only (no terminal print)
- `-N` / `--no-cmd` do **not** include the command header
- `-m` copy as fenced code block (no language)
- `-M <lang>` copy as fenced code block with language (e.g. `-M bash`)
- `-t <lines>` truncate output to first N lines
- `-h` help

## Examples
```sh
cpout echo hej
cpout -N echo hej
cpout -m cue vet schema.cue
cpout -M bash cue vet schema.cue
cpout -t 50 tail -n 1000 big.log
```

Requires macOS pbcopy. (Linux support via xclip/xsel could be added.)
