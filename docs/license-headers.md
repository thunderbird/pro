# MPL license headers

Thunderbird Pro repos are licensed under the [Mozilla Public License 2.0](../LICENSE), which is a per-file license: each covered source file should carry a short header pointing back at it. `scripts/add-license-headers.sh` adds and checks these headers, and `.github/workflows/license-check.yml` runs it in CI.

## Using the script

```sh
# Add missing headers to every tracked file in the repo
./scripts/add-license-headers.sh

# Only check (used by CI) - exits 1 and lists offending files if any are missing a header
./scripts/add-license-headers.sh --check --base main

# Only operate on specific files
./scripts/add-license-headers.sh -- path/to/file.py path/to/other.vue
```

Run `./scripts/add-license-headers.sh --help` for the full option list.

The script only touches file types it knows a comment style for (see `scripts/license-comment-styles.conf`); everything else (images, lockfiles, Markdown, JSON, ...) is left alone. It's idempotent - re-running it never adds a duplicate header.

## Excluding files

Paths matching `.license-ignore` (plain `.gitignore` syntax) are skipped, in addition to any file type absent from `scripts/license-comment-styles.conf`.

If a repo needs its own exclusions or comment-style entries, drop a same-named file at its own root - `.license-ignore` and/or `scripts/license-comment-styles.conf` - and it takes precedence over the copy bundled in `thunderbird/pro`.

## Adopting this in another repo

### Using CI

Add a caller workflow that invokes the reusable workflow hosted here:

```yaml
name: License Header Check
on:
  pull_request:
jobs:
  license-check:
    uses: thunderbird/pro/.github/workflows/license-check.yml@main
```

This checks out your repo plus the tooling from `thunderbird/pro`, then runs `add-license-headers.sh --check` against the files your PR changed.

### Running locally, without CI

Clone `thunderbird/pro` next to your repo and invoke the script from your repo's root:

```sh
# Clone thunderbird/pro as a sibling of your repo
git clone https://github.com/thunderbird/pro.git .pro-license-tools

cd your-repo
../.pro-license-tools/scripts/add-license-headers.sh --check
```

`REPO_ROOT` is resolved from the repo you run it in (via `git rev-parse --show-toplevel`), so it scans and modifies only your repo's own tracked files - never the cloned tooling. If your repo doesn't have its own `.license-ignore` and/or `scripts/license-comment-styles.conf`, the script falls back to the copies bundled in `.pro-license-tools`; drop same-named files at your repo's root to override them.
