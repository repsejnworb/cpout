#!/usr/bin/env bash
#
# release.sh — tag -> push -> build-from-tag -> GitHub release
# Requires: git, zip, gh (logged in), shasum/sha256sum
#
# Usage:
#   ./release.sh                  # bump=patch (default)
#   ./release.sh -b minor         # bump minor
#   ./release.sh -b major -m "Breaking: new flags"
#   ./release.sh --prerelease
#
set -euo pipefail

# ---------- CLI ----------
BUMP="patch"        # patch|minor|major
NOTES=""            # release notes (auto if empty)
PRERELEASE=0

usage() {
  cat <<'USAGE'
Usage: release.sh [-b patch|minor|major] [-m "notes"] [--prerelease]

Options:
  -b <level>     Bump level: patch (default), minor, or major
  -m <notes>     Release notes (default: auto-generated from git log)
  --prerelease   Mark the GitHub release as a prerelease
  -h             Help
USAGE
}

while (( $# )); do
  case "$1" in
    -b) BUMP="${2:-}"; shift 2 ;;
    -m) NOTES="${2:-}"; shift 2 ;;
    --prerelease) PRERELEASE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 64 ;;
  esac
done

case "$BUMP" in patch|minor|major) ;; *) echo "Invalid -b $BUMP" >&2; exit 64 ;; esac

# ---------- Guards ----------
need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 127; }; }
need git; need zip; need gh
if command -v shasum >/dev/null 2>&1; then SHASUM="shasum -a 256"; elif command -v sha256sum >/dev/null 2>&1; then SHASUM="sha256sum"; else echo "Need shasum or sha256sum" >&2; exit 127; fi

[[ -d .git ]] || { echo "Run from the repo root" >&2; exit 1; }
for f in cpout.plugin.zsh _cpout; do
  [[ -e "$f" ]] || { echo "Missing required file: $f" >&2; exit 1; }
done

# Ensure clean working tree (no uncommitted changes)
if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree not clean. Commit or stash changes first." >&2
  exit 1
fi

# Ensure we're on a branch that has an upstream (so the tag pushes to origin)
git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1 || {
  echo "Current branch has no upstream. Push the branch first." >&2
  exit 1
}

# ---------- Compute next tag ----------
last_tag="$(git describe --tags --abbrev=0 2>/dev/null || true)"
[[ -z "$last_tag" ]] && last_tag="v0.0.0"

base="${last_tag#v}"
IFS='.' read -r MAJ MIN PAT <<< "${base:-0.0.0}"
MAJ=${MAJ:-0}; MIN=${MIN:-0}; PAT=${PAT:-0}

case "$BUMP" in
  patch) ((PAT++)) ;;
  minor) ((MIN++)); PAT=0 ;;
  major) ((MAJ++)); MIN=0; PAT=0 ;;
esac

new_tag="v${MAJ}.${MIN}.${PAT}"

# Abort if tag already exists locally or remotely
if git rev-parse -q --verify "refs/tags/$new_tag" >/dev/null; then
  echo "Tag $new_tag already exists locally" >&2; exit 1
fi
if git ls-remote --tags origin "refs/tags/$new_tag" | grep -q .; then
  echo "Tag $new_tag already exists on origin" >&2; exit 1
fi

echo "Last tag : $last_tag"
echo "New tag  : $new_tag (bump: $BUMP)"

# ---------- Create & push tag first (source of truth) ----------
git tag -a "$new_tag" -m "$new_tag"
git push origin "$new_tag"

# ---------- Build artifact from the tag ----------
dist_dir="dist"
mkdir -p "$dist_dir"
zip_path="${dist_dir}/cpout-${new_tag}.zip"
sha_path="${zip_path}.sha256"

# Build exactly from the tagged tree (no dirty working copy)
git archive --format=zip --prefix=cpout/ -o "$zip_path" "$new_tag" cpout.plugin.zsh _cpout
( cd "$dist_dir" && $SHASUM "$(basename "$zip_path")" > "$(basename "$sha_path")" )

echo "Built:"
echo "  $zip_path"
echo "  $sha_path"

# ---------- Release notes ----------
if [[ -z "$NOTES" ]]; then
  if [[ "$last_tag" == "v0.0.0" ]]; then
    NOTES="$(git log --pretty=format:'- %s' "$new_tag")"
  else
    NOTES="$(git log --pretty=format:'- %s' "${last_tag}..${new_tag}")"
  fi
  [[ -n "$NOTES" ]] || NOTES="Release ${new_tag}"
fi

# ---------- Create GitHub Release ----------
args=( release create "$new_tag" "$zip_path" "$sha_path" --title "$new_tag" --notes "$NOTES" )
(( PRERELEASE )) && args+=( --prerelease )

echo "Publishing GitHub release ${new_tag}..."
gh "${args[@]}"

echo "Done."
echo "Tag:       $new_tag"
echo "Artifact:  $zip_path"
