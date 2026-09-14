#!/usr/bin/env bash
#
# Asserts properties of the built site that are deliberate choices rather
# than Quartz defaults, and that would otherwise break silently — most
# likely after pulling a new Quartz version, where a merge conflict gets
# resolved in favour of upstream and a local customisation disappears
# without any error.
#
# Assert the OUTCOME (does the graph render?) rather than the diff (is
# line N still deleted?), so these keep working if Quartz reorganises its
# config format.
#
# Run after `npx quartz build`. A non-zero exit fails the deploy.

set -uo pipefail

fail=0

check() { # description, path under public/, grep pattern
  local desc=$1 file=$2 pattern=$3
  if [[ ! -f "public/$file" ]]; then
    printf 'FAIL  %s\n      public/%s was not emitted\n' "$desc" "$file"
    fail=1
  elif grep -q "$pattern" "public/$file"; then
    printf 'ok    %s\n' "$desc"
  else
    printf 'FAIL  %s\n      public/%s has no match for: %s\n' "$desc" "$file" "$pattern"
    fail=1
  fi
}

exists() { # description, path under public/
  local desc=$1 file=$2
  if [[ -e "public/$file" ]]; then
    printf 'ok    %s\n' "$desc"
  else
    printf 'FAIL  %s\n      public/%s was not emitted\n' "$desc" "$file"
    fail=1
  fi
}

# Right sidebar on section index pages.
# Quartz ships layout.byPageType with `right: []` for the folder and tag
# page types, which clears the graph, backlinks and table of contents.
# quartz.config.yaml deliberately drops that (see commit 6380101). A new
# Quartz version reinstating the default would remove them again silently.
check "graph on the physics section index"   "physics/index.html"   'class="graph"'
check "graph on the valuation section index" "valuation/index.html" 'class="graph"'
check "table of contents on a section index" "physics/index.html"   'class="toc'

# Source PDFs reach the built site.
# Every note links its source PDF with a page number. If content/sources/
# stopped being copied into the build, every one of those links would 404
# while the notes themselves still rendered perfectly.
exists "lecture 02 source PDF" "sources/physics/lecture-02-1d-kinematics.pdf"

if (( fail )); then
  printf '\nSite invariant check FAILED.\n'
  printf 'Each assertion above has a comment in %s saying why it exists.\n' "$0"
  printf 'If a pull from upstream Quartz reverted a local change, reapply it.\n'
  exit 1
fi

printf '\nAll site invariants hold.\n'
