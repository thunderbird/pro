#!/usr/bin/env bash
# Exercise add-license-headers.sh against scripts/tests/fixtures and assert the results.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ADD_HEADERS="$REPO_ROOT/scripts/add-license-headers.sh"
FIXTURES="$SCRIPT_DIR/fixtures"
MARKER='This Source Code Form is subject to the terms of the Mozilla Public'
cd "$REPO_ROOT"

pass=0
fail=0
ok() { echo "  ok   - $1"; pass=$((pass + 1)); }
bad() { echo "  FAIL - $1"; fail=$((fail + 1)); }

# Files expected to get a header inserted by a default-mode run.
HEADERED_FILES=(no-shebang.js with-shebang.py style.css page.html component.vue)
# Files expected to stay byte-identical to the fixture (no comment style, no extension,
# dotfile, or ignored path).
UNTOUCHED_FILES=(already-has-header.sh notes.md Makefile .env vendor/thirdparty.js)
ALL_FILES=("${HEADERED_FILES[@]}" "${UNTOUCHED_FILES[@]}" symlink-file.js)

scratch="$(mktemp -d -p "$SCRIPT_DIR")"
trap 'rm -rf "$scratch"' EXIT

cp -a "$FIXTURES/." "$scratch/"
ln -s no-shebang.js "$scratch/symlink-file.js"

abs_files=()
for f in "${ALL_FILES[@]}"; do abs_files+=("$scratch/$f"); done

echo "== default mode: add headers =="
"$ADD_HEADERS" -- "${abs_files[@]}" >"$scratch/.add-output.txt" 2>&1
add_status=$?
[ "$add_status" -eq 0 ] && ok "default-mode run exits 0" || bad "default-mode run exited $add_status"

for f in "${HEADERED_FILES[@]}"; do
  if grep -qF -- "$MARKER" "$scratch/$f"; then
    ok "$f: header inserted"
  else
    bad "$f: header NOT inserted"
  fi
done

if [ "$(sed -n '1p' "$scratch/with-shebang.py")" = "#!/usr/bin/env python3" ] \
  && sed -n '3p' "$scratch/with-shebang.py" | grep -qF -- "$MARKER"; then
  ok "with-shebang.py: header inserted after the shebang, not before"
else
  bad "with-shebang.py: header not correctly placed after the shebang"
fi

if sed -n '1p' "$scratch/no-shebang.js" | grep -qF -- "$MARKER"; then
  ok "no-shebang.js: header inserted at the top of the file"
else
  bad "no-shebang.js: header not at the top of the file"
fi

for f in "${UNTOUCHED_FILES[@]}"; do
  if diff -q "$FIXTURES/$f" "$scratch/$f" >/dev/null 2>&1; then
    ok "$f: left untouched"
  else
    bad "$f: was modified but should have been left alone"
  fi
done

if [ -L "$scratch/symlink-file.js" ]; then
  ok "symlink-file.js: still a symlink after the run"
else
  bad "symlink-file.js: was flattened into a regular file"
fi

echo "== default mode re-run: idempotency =="
"$ADD_HEADERS" -- "${abs_files[@]}" >"$scratch/.rerun-output.txt" 2>&1
for f in "${HEADERED_FILES[@]}" already-has-header.sh; do
  count="$(grep -cF -- "$MARKER" "$scratch/$f")"
  [ "$count" -eq 1 ] && ok "$f: header appears exactly once after re-run" || bad "$f: header appears $count times after re-run"
done
if grep -q '^added header:' "$scratch/.rerun-output.txt"; then
  bad "re-run: reported adding a header to an already-headered file"
else
  ok "re-run: added no duplicate headers"
fi

echo "== --check mode: fresh (headerless) fixtures =="
check_scratch="$(mktemp -d -p "$SCRIPT_DIR")"
cp -a "$FIXTURES/." "$check_scratch/"
check_abs=()
for f in "${ALL_FILES[@]}"; do
  [ "$f" = symlink-file.js ] && continue
  check_abs+=("$check_scratch/$f")
done
"$ADD_HEADERS" --check -- "${check_abs[@]}" >"$scratch/.check-output.txt" 2>&1
check_status=$?
[ "$check_status" -eq 1 ] && ok "--check on fresh fixtures exits 1" || bad "--check on fresh fixtures exited $check_status (expected 1)"
for f in "${HEADERED_FILES[@]}"; do
  if grep -qF -- "$check_scratch/$f" "$scratch/.check-output.txt"; then
    ok "--check: reports $f missing"
  else
    bad "--check: did not report $f missing"
  fi
done
for f in "${UNTOUCHED_FILES[@]}"; do
  if grep -qF -- "$check_scratch/$f" "$scratch/.check-output.txt"; then
    bad "--check: incorrectly reported $f as missing a header"
  else
    ok "--check: correctly did not report $f"
  fi
done
rm -rf "$check_scratch"

echo "== --check mode: already-headered files =="
"$ADD_HEADERS" --check -- "${abs_files[@]}" >"$scratch/.check-ok-output.txt" 2>&1
check_ok_status=$?
[ "$check_ok_status" -eq 0 ] && ok "--check on headered files exits 0" || bad "--check on headered files exited $check_ok_status (expected 0)"
if grep -q 'All relevant files have license headers.' "$scratch/.check-ok-output.txt"; then
  ok "--check: reports success message"
else
  bad "--check: missing success message"
fi

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
