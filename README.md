# cpout

> Copy command output to your clipboard — now as a fast standalone Go CLI.

`cpout` runs a command, prints its output, and copies it to your system clipboard.  
It supports truncation, markdown code fencing, and optional command headers — just like the original zsh plugin.

---

## ✨ Features

- ✅ Runs any command and copies its output to clipboard  
- 🧱 Optionally wrap output in Markdown code fences (`-m`, `-M <lang>`)  
- 🔪 Truncate output to first *N* lines (`-t N`)  
- 🧩 Include or omit command header line (`-N`)  
- ⚡ Native Go binary — no shell dependencies, fast startup

---

## 🚀 Installation

Download the latest binary for macOS or Linux from the [releases page](https://github.com/repsejnworb/cpout/releases):

```bash
# Example for macOS arm64:
curl -L https://github.com/repsejnworb/cpout/releases/latest/download/cpout_darwin_arm64.tar.gz \
  | tar xz
sudo mv cpout /usr/local/bin/
```

---

## 🧰 Usage

```bash
cpout [flags] <command> [args...]
```

### Flags
| Flag | Description |
|------|--------------|
| `-N` | Don’t include the “❯ cmd” header line |
| `-m` | Copy as Markdown code block (no language) |
| `-M <lang>` | Copy as Markdown code block with language |
| `-t <n>` | Truncate to the first *n* lines |
| `-q` | Copy only (don’t print) |
| `-S` | Use stdout only (exclude stderr) |

### Examples
```bash
cpout echo hej
cpout -m cue vet schema.cue
cpout -M bash echo hej
cpout -N -q ls -la
cpout -t 10 docker ps
```

---

## 🧩 Building from source

```bash
go install github.com/repsejnworb/cpout@latest
```

or clone manually:

```bash
git clone https://github.com/repsejnworb/cpout
cd cpout
go build -o cpout .
```

---

## 📦 Versioning & Releases

Releases are managed automatically with [release-please](https://github.com/googleapis/release-please).  
Every merged change using [Conventional Commits](https://www.conventionalcommits.org/) triggers an automatic version bump, changelog, and binary build for macOS and Linux.

