# -----------------------------------------------------------------------------
# name: cpout
# repo: github.com/repsejnworb/cpout
# description: Copy command output to the clipboard with optional markdown fencing.
# -----------------------------------------------------------------------------
typeset -a CP_FLAG_SPEC=(
  'S|-|-|stdout only (exclude stderr)'
  'q|-|-|copy only (no terminal print)'
  'c|-|-|include the command header (default)'
  'N|no-cmd|-|do NOT include the command header'
  'm|-|-|copy as fenced code block (no language)'
  'M|-|arg|copy as fenced code block with language (e.g., bash)'
  't|-|arg|truncate output to first N lines'
  'h|-|-|help'
)

# Build getopts string from spec (e.g., "SqcNmM:t:h")
_cpout_build_getopts() {
  local s short req
  local str=""
  for s in "${CP_FLAG_SPEC[@]}"; do
    short="${s%%|*}"; s="${s#*|}"           # short
    : "${s%%|*}"; s="${s#*|}"               # long (unused here)
    req="${s%%|*}"                          # requiredArg
    [[ "$short" = "-" ]] && continue
    if [[ "$req" = "arg" ]]; then
      str+="${short}:"
    else
      str+="$short"
    fi
    s="${s#*|}"                             # desc (unused)
  done
  print -r -- "$str"
}

# Print usage from spec
_cpout_usage() {
  cat <<'HDR'
Usage: cpout [-S] [-q] [-N] [-m|-M <lang>] [-t <lines>] [-c] <command> [args...]
  Default: Print AND copy combined stdout+stderr, includes "❯ cmd" header
Options:
HDR
  local s short long req desc pad
  for s in "${CP_FLAG_SPEC[@]}"; do
    short="${s%%|*}"; s="${s#*|}"
    long="${s%%|*}";  s="${s#*|}"
    req="${s%%|*}";   s="${s#*|}"
    desc="$s"
    pad='  -'"$short"
    [[ "$req" = "arg" ]] && pad="$pad"' <arg>'
    [[ "$long" != "-" ]] && pad="$pad"', --'"$long"
    printf "  %-28s %s\n" "$pad" "$desc"
  done
}

# Map long options to short ones using the spec (so we keep 1 source)
_cpout_long_to_short() {
  local -a out=()
  local a s short long req desc
  for a in "$@"; do
    if [[ "$a" == --* ]]; then
      local name="${a#--}" matched=0
      for s in "${CP_FLAG_SPEC[@]}"; do
        short="${s%%|*}"; s="${s#*|}"
        long="${s%%|*}";  s="${s#*|}"
        req="${s%%|*}";   s="${s#*|}"; desc="$s"
        if [[ "$long" = "$name" ]]; then
          if [[ "$req" = "arg" ]]; then
            out+=("-$short")  # value stays as next argv
          else
            out+=("-$short")
          fi
          matched=1; break
        fi
      done
      (( matched )) || out+=("$a")  # unknown long: leave as-is
    else
      out+=("$a")
    fi
  done
  print -r -l -- "${out[@]}"
}

# ---------- Main function ----------
cpout() {
  local GETOPTS_STR="$(_cpout_build_getopts)"

  # Defaults
  local stdout_only=0 copy_only=0 include_cmd=1 markdown=0 fence_lang=""
  local truncate_lines=0

  # Translate long options → short using spec, then use getopts
  local -a argv_translated
  # split the command-substitution output on NEWLINES into array items
  argv_translated=("${(@f)$(_cpout_long_to_short "$@")}")
  set -- "${argv_translated[@]}"

  local opt
  while getopts "$GETOPTS_STR" opt; do
    case "$opt" in
      S) stdout_only=1 ;;
      q) copy_only=1 ;;
      c) include_cmd=1 ;;
      N) include_cmd=0 ;;
      m) markdown=1; fence_lang="" ;;
      M) markdown=1; fence_lang="$OPTARG" ;;
      t) truncate_lines="$OPTARG" ;;
      h) _cpout_usage; return 0 ;;
      \?) _cpout_usage; return 64 ;;
    esac
  done
  shift $((OPTIND-1))

  if ! command -v pbcopy >/dev/null 2>&1; then
    print -u2 "cpout: pbcopy not found (macOS)"; return 127
  fi
  if [[ $# -eq 0 ]]; then
    print -u2 "cpout: missing command. See: cpout -h"; return 64
  fi
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

  # Optional truncate
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

  # Clipboard text (optionally fenced; safe concatenation)
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
