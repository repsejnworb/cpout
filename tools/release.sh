#!/usr/bin/env bash
#
# release.sh — autobump version, build artifact, and publish a GitHub Release
# Requires: git, zip, gh (authenticated), shasum/sha256sum
# Repo layout expected:
#   cpout.plugin.zsh
#   _cpout
#
# Examples:
#   ./release.sh                # bump=patch (default), build + tag + release
#   ./release.sh -b minor       # bump minor
#   ./release.sh -b major -m "Breaking: new flags"
#   ./release.sh --prerelease   # mark release as pre-release
#   ./release.sh --build-only   # just build artifact for the computed next tag, no tag/release
#
set -euo pipefail

# -----------------------
# Defaults & CLI parsing
# -----------------------
BUMP="patch"      # patch|minor|major
NOTES=""          # release notes (auto-generated if empty)
PRERELEASE=0
BUILD_ONLY=0

usage() {
  cat <<'USAGE'
Usage: release.sh [-b patch|minor|major] [-m "notes"] [--prerelease] [--build-only]

Options:
  -b <level>     Bump level: patch (default), minor, or major
  -m <notes>     Release notes (default: auto-generated from git log)
  --prerelease   Mark the GitHub release as a prerelease
  --build-only   Only build the artifact; do not tag or create a release
  -h             Help

Examples:
  ./release.sh
  ./release.sh -b minor -m "Add completion & README"
  ./release.sh -b major --prerelease
  ./release.sh --build-only
USAGE
}

# Parse args
while (( $# )); do
  case "$1" in
    -b) BUMP="${2:-}"; shift 2 ;;
    -m) NOTES="${2:-}"; shift 2 ;;
    --prerelease) PRERELEASE=1; shift ;;
    --build-only) BUILD_ONLY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 64 ;;
  esac
done

case "$BUMP" in
  patch|minor|major) ;; 
  *) echo "Invalid bump level: $BUMP (expected patch|minor|major)" >&2; exit 64 ;;
esac

# -----------------------
# Guards
# -----------------------
command -v git >/dev/null 2>&1 || { echo "git not found" >&2; exit 127; }
command -v zip >/dev/null 2>&1 || { echo "zip not found" >&2; exit 127; }
if command -v shasum >/dev/null 2>&1; then
  SHASUM="shasum -a 256"
elif command -v sha256sum >/dev/null 2>&1; then
  SHASUM="sha256sum"
else
  echo "No shasum/sha256sum found" >&2; exit 127
fi

if (( ! BUILD_ONLY )); then
  command -v gh >/dev/null 2>&1 || { echo "gh CLI not found (brew install gh). Also run 'gh auth login'." >&2; exit 127; }
fi

# Ensure we’re at repo root (has .git and plugin files)
if [[ ! -d .git ]]; then
  echo "Run from the root of the git repo." >&2
  exit 1
fi
for f in cpout.plugin.zsh _cpout; do
  [[ -e "$f" ]] || { echo "Missing required file: $f" >&2; exit 1; }
done

# Working tree clean?
if (( ! BUILD_ONLY )); then
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "Working tree not clean. Commit or stash changes first." >&2
    exit 1
  fi
fi

# -----------------------
# Compute next version
# -----------------------
last_tag="$(git describe --tags --abbrev=0 2>/dev/null || true)"
if [[ -z "$last_tag" ]]; then
  last_tag="v0.0.0"
fi

# strip leading 'v'
base="${last_tag#v}"
IFS='.' read -r MAJ MIN PAT <<<"${base:-0.0.0}"
MAJ=${MAJ:-0}; MIN=${MIN:-0}; PAT=${PAT:-0}

case "$BUMP" in
  patch) ((PAT++)) ;;
  minor) ((MIN++)); PAT=0 ;;
  major) ((MAJ++)); MIN=0; PAT=0 ;;
esac

new_tag="v${MAJ}.${MIN}.${PAT}"

# -----------------------
# Build artifact (zip + sha256)
# -----------------------
dist_dir="dist"
mkdir -p "$dist_dir"

zip_name="cpout-${new_tag}.zip"
zip_path="${dist_dir}/${zip_name}"
sha_path="${zip_path}.sha256"

# Build a clean zip with a top-level folder prefix "cpout/"
# Use the tracked files; prefer git archive if you want exactly tagged content.
# For BUILD_ONLY we just zip current working tree files.
(
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT
  mkdir -p "$tmpdir/cpout"
  cp -f cpout.plugin.zsh _cpout "$tmpdir/cpout/"
  (cd "$tmpdir" && zip -rq "$OLDPWD/$zip_path" cpout)
)

# Checksum
( cd "$dist_dir" && $SHASUM "$zip_name" > "$(basename "$sha_path")" )

echo "Built:"
echo "  $zip_path"
echo "  $sha_path"

# -----------------------
# If --build-only, stop here
# -----------------------
if (( BUILD_ONLY )); then
  echo "Build-only mode: not tagging or creating a GitHub release."
  echo "Next version would be: $new_tag (from $last_tag via $BUMP)"
  exit 0
fi

# -----------------------
# Create tag locally & push
# -----------------------
git tag -a "$new_tag" -m "$new_tag"
git push origin "$new_tag"

# -----------------------
# Release notes
# -----------------------
if [[ -z "$NOTES" ]]; then
  # Auto-generate notes from git log since last tag (or full history if v0.0.0)
  if [[ "$last_tag" == "v0.0.0" ]]; then
    NOTES="$(git log --pretty=format:'- %s')"
  else
    NOTES="$(git log --pretty=format:'- %s' "${last_tag}..HEAD")"
  fi
  # Fallback if empty
  [[ -n "$NOTES" ]] || NOTES="Release ${new_tag}"
fi

# -----------------------
# Create GitHub release
# -----------------------
gh_args=( release create "$new_tag" "$zip_path" "$sha_path" --title "$new_tag" --notes "$NOTES" )
if (( PRERELEASE )); then
  gh_args+=( --prerelease )
fi

echo "Publishing GitHub release ${new_tag}..."
gh "${gh_args[@]}"

echo "Done."
echo "Tag:        $new_tag"
echo "Prev tag:   $last_tag"
echo "Artifact:   $zip_path"
