# cpout

Run any command, print its output, and copy it to your clipboard — all in one step.  
Supports markdown fencing, truncation, and optional inclusion of the command line.

---

## 🚀 Features

- Prints **and** copies command output by default  
- Supports **stdout-only**, **silent copy**, and **markdown fenced** modes  
- Optional truncation (`-t N`) for long outputs  
- Designed as an **Oh My Zsh plugin** with tab completion  
- Zero dependencies beyond `pbcopy` (macOS)

---

## 📦 Installation

### Option 1 — Install from GitHub release (recommended)

Download the latest packaged zip and extract it under your custom OMZ plugins folder:

```bash
cd ~/.oh-my-zsh/custom/plugins
curl -LO https://github.com/repsejnworb/cpout/releases/latest/download/cpout-latest.zip
unzip cpout-latest.zip -d cpout
```

> Each release also includes a `cpout-<version>.zip.sha256` checksum.

Then enable it in your `~/.zshrc`:

```zsh
plugins=(... cpout)
```

and reload your shell:

```bash
omz reload
```

---

### Option 2 — Clone directly from GitHub

```bash
git clone https://github.com/repsejnworb/cpout ~/.oh-my-zsh/custom/plugins/cpout
```

Enable in `.zshrc` as above.

---

## 🧠 Usage

```bash
cpout [-S] [-q] [-N] [-m|-M <lang>] [-t <lines>] [-c] <command> [args...]
```

**Examples**

```bash
cpout echo hej                     # print & copy
cpout -N echo hej                  # copy only result, no header
cpout -m cue vet schema.cue        # copy as markdown codeblock
cpout -M bash cue vet schema.cue   # codeblock with language
cpout -t 50 tail -n 1000 big.log   # truncate to first 50 lines
```

Clipboard content examples:

**Default**

```
❯ echo hej
hej
```

**Markdown fenced**

```bash
❯ echo hej
hej
```

---

## 🧩 Completions

If loaded via Oh My Zsh, completions for flags (`-S`, `-q`, `-m`, etc.) are auto-enabled.  
To disable completions, simply omit `_cpout` from the plugin directory.
