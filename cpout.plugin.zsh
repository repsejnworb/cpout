# cpout — run a command and copy its output to the clipboard
# Default: print & copy combined stdout+stderr, and include the command line.
# Flags:
#   -S           stdout only (exclude stderr)
#   -q           copy only (no terminal print)
#   -c           include the command line (default; kept for backward compat)
#   -N, --no-cmd do NOT include the command line
#   -m           copy as fenced code block (no language)
#   -M <lang>    copy as fenced code block with language (e.g., -M bash)
#   -t <lines>   truncate output to the first <lines> lines (printed + copied)
#   -h           help
cpout() {
  local stdout_only=0 copy_only=0 include_cmd=1 markdown=0 fence_lang="" truncate_lines=0
  local opt
  # NOTE: M: means -M takes an argument
  while getopts "SqcNmM:t:h" opt; do
    case "$opt" in
      S) stdout_only=1 ;;
      q) copy_only=1 ;;
      c) include_cmd=1 ;;        # default is already ON
      N) include_cmd=0 ;;
      m) markdown=1 ;;
      M) markdown=1; fence_lang="$OPTARG" ;;
      t) truncate_lines="$OPTARG" ;;
      h)
        cat <<'USAGE'
Usage: cpout [-S] [-q] [-N] [-m|-M <lang>] [-t <lines>] [-c] <command> [args...]
  (default)  Print AND copy combined stdout+stderr, includes "❯ cmd" header
  -S         Use stdout only (exclude stderr)
  -q         Copy only (silent; don't print to terminal)
  -N         Do NOT include the command line header in the copied text
  -m         Copy as fenced code block (no language)
  -M <lang>  Copy as fenced code block with language (e.g., -M bash)
  -t <lines> Truncate output to the first <lines> lines (printed + copied)
  -c         Include the command line (legacy toggle; default is ON)
  -h         Help
USAGE
        return 0 ;;
    esac
  done
  shift $((OPTIND-1))

  # Support long flag --no-cmd anywhere after getopts
  if [[ "$1" == "--no-cmd" ]]; then
    include_cmd=0
    shift
  fi

  if ! command -v pbcopy >/dev/null 2>&1; then
    print -u2 "cpout: pbcopy not found (macOS)"; return 127
  fi
  if [[ $# -eq 0 ]]; then
    print -u2 "cpout: usage: cpout [-S] [-q] [-N] [-m|-M <lang>] [-t <lines>] <command> [args…]"
    return 64
  fi
  # Validate -t argument if provided (allow 0 = no truncation)
  if [[ -n "$truncate_lines" && "$truncate_lines" != 0 && "$truncate_lines" != <-> ]]; then
    print -u2 "cpout: -t expects a positive integer"; return 64
  fi

  setopt local_options pipefail

  # Build command header (safely quoted)
  local header=""
  if (( include_cmd )); then
    local cmd_str="" arg
    for arg in "$@"; do
      cmd_str+="${cmd_str:+ }$(printf '%q' "$arg")"
    done
    header="❯ $cmd_str"$'\n'
  fi

  # Run command and capture output
  local out exit_status
  if (( stdout_only )); then
    out="$("$@")"; exit_status=$?
  else
    out="$("$@" 2>&1)"; exit_status=$?
  fi

  # Optionally truncate to N lines (affects both terminal + clipboard)
  local display_out="$out"
  if (( truncate_lines > 0 )); then
    display_out="$(print -r -- "$out" | head -n "$truncate_lines")"
    local orig_lines truncated
    orig_lines=$(print -r -- "$out" | wc -l | awk '{print $1}')
    truncated=$(print -r -- "$display_out" | wc -l | awk '{print $1}')
    if (( orig_lines > truncated )); then
      display_out+=$'\n''… (truncated)'
    fi
  fi

  # Terminal print (never fenced)
  if (( ! copy_only )); then
    [[ -n $header ]] && printf "%s" "$header"
    printf "%s" "$display_out"
    [[ "$display_out" != *$'\n' ]] && printf "\n"
  fi

  # Clipboard text (optionally fenced)
  local clip="$header$display_out"
  if (( markdown )); then
    if [[ -n "$fence_lang" ]]; then
      clip='```'"$fence_lang"$'\n'"$clip"$'\n''```'
    else
      clip=$'```\n'"$clip"$'\n```'
    fi
  fi

  printf "%s" "$clip" | pbcopy

  return $exit_status
}
