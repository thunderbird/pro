#!/usr/bin/env bash
# Add or check MPL 2.0 license headers on source files.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel)"

CHECK_MODE=0
BASE_REF=""
IGNORE_FILE="$REPO_ROOT/.license-ignore"
[ -f "$IGNORE_FILE" ] || IGNORE_FILE="$(dirname "$SCRIPT_DIR")/.license-ignore"
STYLE_MAP="$REPO_ROOT/scripts/license-comment-styles.conf"
[ -f "$STYLE_MAP" ] || STYLE_MAP="$SCRIPT_DIR/license-comment-styles.conf"
FILES=()
EXPLICIT_FILES=0

# Content for help and usage
usage() {
  cat <<'EOF'
Check or add MPL 2.0 license headers on source files.

Usage:
  add-license-headers.sh [--check] [--ignore-file PATH] [--style-map PATH] [--base REF]
  add-license-headers.sh [--check] [--ignore-file PATH] [--style-map PATH] -- FILE...
  add-license-headers.sh -h|--help

Modes:
  (default)           Insert the MPL header into any relevant file that's missing one.
  --check             Report-only: exit 1 if any relevant file is missing its header.

Target selection (mutually exclusive):
  (no args)           Scan every tracked file (git ls-files).
  --base REF          Only files changed relative to REF (git diff --name-only REF...HEAD).
  -- FILE...          Only the given file paths.

Options:
  --ignore-file PATH  Override the gitignore-syntax exclusion list
                      (default: <repo-root>/.license-ignore,
                      falling back to the copy in this script's own repo).
  --style-map PATH    Override the extension-to-comment-style table
                      (default: <repo-root>/scripts/license-comment-styles.conf,
                      falling back to the copy bundled next to this script).

Examples:
  ./scripts/add-license-headers.sh                       # add headers repo-wide
  ./scripts/add-license-headers.sh --check --base main   # what CI runs
  ./scripts/add-license-headers.sh -- foo.py bar.vue     # only these files
EOF
}

# Parse command-line arguments.
while [ $# -gt 0 ]; do
  case "$1" in
    --check) CHECK_MODE=1; shift ;;
    --base) BASE_REF="$2"; shift 2 ;;
    --ignore-file) IGNORE_FILE="$2"; shift 2 ;;
    --style-map) STYLE_MAP="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    --) shift; FILES=("$@"); EXPLICIT_FILES=1; break ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

# Reject incompatible target-selection options.
if [ -n "$BASE_REF" ] && [ "$EXPLICIT_FILES" -eq 1 ]; then
  echo "error: --base and -- FILE... are mutually exclusive" >&2
  usage >&2
  exit 2
fi

# Validate the base ref before it's used to select files.
if [ -n "$BASE_REF" ]; then
  if ! git -C "$REPO_ROOT" rev-parse --verify --quiet "${BASE_REF}^{commit}" >/dev/null; then
    echo "error: --base ref '$BASE_REF' does not resolve to a commit in this repository" >&2
    exit 2
  fi
fi

# Determine which files to scan when none were given explicitly.
if [ ${#FILES[@]} -eq 0 ]; then
  if [ -n "$BASE_REF" ]; then
    mapfile -t FILES < <(git -C "$REPO_ROOT" diff --name-only --diff-filter=ACMR "${BASE_REF}...HEAD")
  else
    mapfile -t FILES < <(git -C "$REPO_ROOT" ls-files)
  fi
fi

# Substring shared verbatim by every style template below; used to detect existing license headers.
MARKER='This Source Code Form is subject to the terms of the Mozilla Public'

# Look up the comment style for a file extension in the style map.
style_for_ext() {
  local ext="$1"
  [ -f "$STYLE_MAP" ] || return 1
  awk -v ext="$ext" '$1 == ext { print $2; found=1; exit } END { exit !found }' "$STYLE_MAP"
}

# Check whether a path matches the ignore file's gitignore-style patterns.
is_ignored() {
  local path="$1"
  [ -f "$IGNORE_FILE" ] || return 1
  git -C "$REPO_ROOT" -c core.excludesFile="$IGNORE_FILE" check-ignore --no-index -q -- "$path"
}

# Render the license header text for a given comment style.
header_for_style() {
  case "$1" in
    slash)
      printf '// %s\n// License, v. 2.0. If a copy of the MPL was not distributed with this\n// file, You can obtain one at http://mozilla.org/MPL/2.0/.\n' "$MARKER" ;;
    hash)
      printf '# %s\n# License, v. 2.0. If a copy of the MPL was not distributed with this\n# file, You can obtain one at http://mozilla.org/MPL/2.0/.\n' "$MARKER" ;;
    block)
      printf '/*\n * %s\n * License, v. 2.0. If a copy of the MPL was not distributed with this\n * file, You can obtain one at http://mozilla.org/MPL/2.0/.\n */\n' "$MARKER" ;;
    html)
      printf '<!--\n  %s\n  License, v. 2.0. If a copy of the MPL was not distributed with this\n  file, You can obtain one at http://mozilla.org/MPL/2.0/.\n-->\n' "$MARKER" ;;
    jinja)
      printf '{#\n  %s\n  License, v. 2.0. If a copy of the MPL was not distributed with this\n  file, You can obtain one at http://mozilla.org/MPL/2.0/.\n#}\n' "$MARKER" ;;
    *)
      return 1 ;;
  esac
}

# Insert after a shebang line if present, otherwise at the top of the file.
insert_header() {
  local target="$1" header="$2" tmp mode
  tmp="$(mktemp)"
  if [[ "$(head -n1 -- "$target")" == '#!'* ]]; then
    { head -n1 -- "$target"; printf '\n%s\n' "$header"; tail -n +2 -- "$target"; } > "$tmp"
  else
    { printf '%s\n' "$header"; cat -- "$target"; } > "$tmp"
  fi
  mode="$(stat -c '%a' -- "$target" 2>/dev/null || stat -f '%Lp' -- "$target")"
  chmod "$mode" "$tmp"
  mv -- "$tmp" "$target"
}

# Memory for report
missing=()
already_had=0
ignored_count=0
skipped_symlinks=0

# Process each candidate file, adding or checking its license header.
for file in "${FILES[@]}"; do
  # Resolve the absolute path differently depending on how the file was selected.
  if [ "$EXPLICIT_FILES" -eq 1 ]; then
    path="$file"
    case "$path" in
      /*) : ;;                # already absolute
      *) path="$PWD/$path" ;; # anchor to the invoking cwd, not $REPO_ROOT, so is_ignored's
                              # "git -C $REPO_ROOT check-ignore" resolves the right file
    esac
  else
    path="$REPO_ROOT/$file"
  fi

  # Handle symlinks: never flatten a tracked symlink into a regular file
  if [ -L "$path" ]; then
    skipped_symlinks=$((skipped_symlinks + 1))
    continue
  fi
  [ -f "$path" ] || continue

  base="${file##*/}"
  ext="${base##*.}"
  [ "$ext" = "$base" ] && continue # no dot at all, e.g. "Makefile"
  [ -z "${base%.*}" ] && continue  # dotfile with nothing before the (only) dot, e.g. ".gitignore"

  style="$(style_for_ext "$ext")" || continue # extension not in style map

  # Skip files excluded by the ignore list.
  if is_ignored "$path"; then
    ignored_count=$((ignored_count + 1))
    continue
  fi

  # Skip files that already have the license header.
  if grep -qF -- "$MARKER" "$path"; then
    already_had=$((already_had + 1))
    continue
  fi

  # Record as missing in check mode, otherwise insert the header now.
  if [ "$CHECK_MODE" -eq 1 ]; then
    missing+=("$file")
  else
    insert_header "$path" "$(header_for_style "$style")"
    echo "added header: $file"
  fi
done

# Report results: fail with the missing-file list in check mode, else print a summary.
if [ "$CHECK_MODE" -eq 1 ]; then
  if [ ${#missing[@]} -gt 0 ]; then
    echo "Missing MPL license header in ${#missing[@]} file(s):" >&2
    printf '  %s\n' "${missing[@]}" >&2
    echo >&2
    echo "Re-run '$0' without --check to write them to the files, then commit." >&2
    exit 1
  fi
  echo "All relevant files have license headers."
else
  echo "Done. ${already_had} file(s) already had a header, ${ignored_count} ignored, ${skipped_symlinks} symlink(s) skipped."
fi
