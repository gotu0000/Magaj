#!/bin/bash
#
# Runs automatically when a Claude Code session opens, before the first turn.
#
# Why this exists: a web session gets a fresh container every time, with no
# poppler installed. Without pdftoppm the Read tool cannot open a PDF at all,
# so step 1 of "Processing a lecture PDF" fails on the very first action of
# the session. This makes the tools present before that happens.
#
# Design rule: this hook must never stop a session from opening, and no step
# may block a later, unrelated step. Each part fails on its own and warns.

set -euo pipefail

# Local checkouts already have whatever you installed yourself, and should
# never have apt-get run against them. Web sessions only.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Installers are noisy: apt warns about third-party PPAs the egress proxy
# blocks, and prints a progress bar, none of which matters when it works.
# Everything goes to this log, and the log is only shown if a step fails.
log="$(mktemp)"
trap 'rm -f "$log"' EXIT

# --- poppler-utils -------------------------------------------------------
# Deliberately first, and deliberately before any cd: pdftoppm needs nothing
# from the repo, so nothing about the repo should be able to prevent it being
# installed. Reading a PDF is the one thing this hook exists to guarantee.
#
# pdftoppm renders a PDF page to an image so it can actually be looked at,
# and crops a region at high resolution for the zoom rule in CLAUDE.md.
# Guarded by command -v because apt-get update is slow and the container is
# cached after this hook completes.
if ! command -v pdftoppm >/dev/null 2>&1; then
  # apt-get update first: without it the install 404s on a stale package index.
  if DEBIAN_FRONTEND=noninteractive apt-get update -qq >>"$log" 2>&1 \
     && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq poppler-utils >>"$log" 2>&1; then
    echo "session-start: installed poppler-utils"
  else
    # Not fatal. A session that opens with a warning is more useful than one
    # that refuses to open — you can still ask what broke.
    echo "session-start: WARNING poppler-utils failed to install;" \
         "reading PDF pages will not work until it is installed" >&2
    tail -20 "$log" >&2
  fi
fi

# --- node dependencies ---------------------------------------------------
# Needed for `npx quartz build`, which CLAUDE.md's "verify, don't reason"
# rule requires before making any claim about how the site renders.
#
# This half does need the repo, so the cd lives here rather than at the top,
# and its failure is caught: a project directory we cannot enter should cost
# you the site build, not the ability to read a PDF.
#
# npm install, not npm ci: it is incremental (~1s when warm) and reuses the
# cached container, where npm ci deletes node_modules and starts over.
# Verified it leaves the working tree and package-lock.json untouched.
if cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}" 2>/dev/null; then
  if npm install --no-audit --no-fund >>"$log" 2>&1; then
    echo "session-start: node dependencies ready"
  else
    echo "session-start: WARNING npm install failed; the site cannot be built" >&2
    tail -20 "$log" >&2
  fi
else
  echo "session-start: WARNING could not enter the project directory;" \
       "skipping npm install, so the site cannot be built" >&2
fi

# Chromium for screenshots is already baked into the image at
# /opt/pw-browsers — nothing to install.

# Always succeed. A non-zero exit from this hook must never be the reason a
# session fails to open; every real problem above has already been reported.
exit 0
