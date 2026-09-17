#!/bin/bash
#
# Runs automatically when a Claude Code session opens, before the first turn.
#
# Why this exists: a web session gets a fresh container every time, with no
# poppler installed. Without pdftoppm the Read tool cannot open a PDF at all,
# so step 1 of "Processing a lecture PDF" fails on the very first action of
# the session. This makes the tools present before that happens.
#
# Design rules:
#   1. This hook must never stop a session from opening.
#   2. No step may block a later, unrelated step.
#   3. Nothing may hang. This hook is synchronous, so a stalled installer
#      would mean the session never opens at all and you could not even ask
#      why. Every network step is bounded by a timeout.

set -euo pipefail

# Overridable so the timeout branches can be exercised, e.g. APT_TIMEOUT=1.
# Measured: apt update+install ~12s; npm install ~1s warm, minutes cold
# because node_modules is roughly 327 MB.
APT_TIMEOUT="${APT_TIMEOUT:-180}"
NPM_TIMEOUT="${NPM_TIMEOUT:-300}"

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
  rc=0
  # apt-get update first: without it the install 404s on a stale package index.
  # `|| rc=$?` keeps set -e from aborting, and captures 124 from a timeout.
  DEBIAN_FRONTEND=noninteractive timeout "$APT_TIMEOUT" apt-get update -qq >>"$log" 2>&1 \
    && DEBIAN_FRONTEND=noninteractive timeout "$APT_TIMEOUT" apt-get install -y -qq poppler-utils >>"$log" 2>&1 \
    || rc=$?

  if [ "$rc" -eq 0 ]; then
    echo "session-start: installed poppler-utils"
  else
    # Not fatal. A session that opens with a warning is more useful than one
    # that refuses to open — you can still ask what broke.
    if [ "$rc" -eq 124 ]; then
      echo "session-start: WARNING poppler-utils install timed out after ${APT_TIMEOUT}s;" \
           "reading PDF pages will not work until it is installed" >&2
    else
      echo "session-start: WARNING poppler-utils failed to install (exit $rc);" \
           "reading PDF pages will not work until it is installed" >&2
    fi
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
  rc=0
  timeout "$NPM_TIMEOUT" npm install --no-audit --no-fund >>"$log" 2>&1 || rc=$?

  if [ "$rc" -eq 0 ]; then
    echo "session-start: node dependencies ready"
  elif [ "$rc" -eq 124 ]; then
    echo "session-start: WARNING npm install timed out after ${NPM_TIMEOUT}s;" \
         "the site cannot be built" >&2
    tail -20 "$log" >&2
  else
    echo "session-start: WARNING npm install failed (exit $rc); the site cannot be built" >&2
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
