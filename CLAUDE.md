# Vault conventions

This repository is a personal knowledge base built on Quartz. Notes are
typed **index and recall layer** over handwritten lecture notes. The
handwritten PDFs are the ground truth; markdown notes exist so concepts
can be searched, linked, and scanned quickly.

Notes are **scan-optimized, not comprehensive**. Detail lives in the
source PDF.

---

## Core operating principle

**Show, wait, write.** Never write files or commit without approval.

Three checkpoints in every lecture-processing session:

1. Extracted concept list → STOP
2. Transcription output → STOP
3. `git status` and diff → STOP

At each one, present the result in the conversation and wait for an
explicit instruction. Do not proceed on assumed approval.

**Verify, don't reason.** Before stating how the site renders or
behaves, build it and look — `npx quartz build`, then read the emitted
HTML under `public/`, or screenshot the page with headless Chromium.
Reading `quartz.config.yaml` or the Quartz source is not enough; it has
produced confident wrong answers more than once.

The same applies to two other things. Before quoting a rule from this
file, re-read the line — do not paraphrase from memory, and never
present your own inference as a rule that lives here, least of all
in a `%%` comment, which a later session reads as settled convention.
Before stating how Claude Code itself works — hook events, payload
fields, tooling — check the documentation rather than recalling it.

---

## Repository structure

```
content/
├── index.md                  site landing page
├── physics/
│   ├── index.md              section landing page
│   ├── lectures/             thin index notes, one per lecture
│   └── *.md                  atomic concept notes
├── valuation/
├── inbox/                    unprocessed PDFs (should normally be empty)
└── sources/                  processed PDFs, permanent
    ├── physics/
    └── valuation/
```

Concept notes live at the domain root. Course/lecture folders hold only
index notes that point at concepts. A concept has **one** note even if
several courses cover it.

---

## Processing a lecture PDF

When a PDF is uploaded to the session or appears in `content/inbox/`:

0. If the PDF was **uploaded to this session**, it is not in the repo
   yet — it must be copied in or it will be lost.
   - I will describe it in plain language, e.g. "physics lecture 1,
     units" or "valuation lecture 3". **You** convert that to the
     filename convention below. I will not type slugs.
   - I will not give lecture numbers. **You assign them.**
   - If I don't give the domain, infer it from the PDF content.

   **Two kinds of material:**
   - **Series** — part of a course. I say `physics lecture: units`.
     You assign the next number in sequence in
     `content/sources/<domain>/` → `lecture-03-units.pdf`
   - **Standalone** — not part of any course: a paper, an article, a
     one-off topic. I say `physics: renormalization` with no
     "lecture". No number → `renormalization.pdf`

   Never renumber or rename anything already in `sources/`.
   If the assigned number looks wrong to me, I will correct it at the
   checkpoint below.
1. Read the PDF. Extract the concept list. Show it, **together with
   the filename you derived**, and **STOP**.
   Do not write anything yet — concepts may be cut or merged, and the
   filename may be wrong.
   - If a concept is uncertain, list it and mark it `(?)`.
   - If the pages are too unclear to extract anything, say so plainly
     and **ask me to list the concepts**. Do not invent a plausible
     list from the topic name.
   - Partial is fine: show what you found, say what you may have
     missed, and I will fill the gaps.
2. After confirmation, transcribe. Show the result in the
   conversation. **STOP.** (See transcription rules below.)
3. After confirmation, write files:
   - one thin lecture index note in `<domain>/lectures/`
   - one atomic concept note per confirmed concept
   - never a single monolithic lecture note
4. Ask the interview question (below). Wait for the answer.
5. Move the PDF from `content/inbox/` to `content/sources/`.
6. Regenerate the affected section `index.md`.
7. Show `git status` and the diff. **STOP.**
8. On approval: commit PDF and notes **together** in one commit,
   message `physics: lecture 02 — 1d kinematics`. Push to `main`.

---

## Transcription

- Never guess at an unreadable symbol. Emit `⟨?⟩` and list it under a
  `## Transcription flags` heading with the line it appears on.
- Zoom before committing to a symbol that changes meaning — a unit,
  exponent, subscript or sign. Crop that region and re-render it at
  high resolution; the page-level view is not enough. A cursive `c`
  joined to the next letter reads as an extra hump, which made `cm`
  transcribe as `mm` twice on lecture 02 p.3. Crop with
  `pdftoppm -f <page> -l <page> -r 400 -x <x> -y <y> -W <w> -H <h> -png <pdf> <out>`.
  Those coordinates are in 400-dpi pixels, so scale up from where the
  symbol sits on the full-page view; expect two attempts to frame it.
- After transcribing, re-read the source and report every symbol below
  high confidence.
- Do not "clean up" math that looks wrong. Transcribe as written and
  flag the discrepancy separately.
- Transcribe what is clear, flag what is not, and **show the result
  before writing any file**.
- Do not decide on your own what to keep, drop, or fall back to —
  including the parts that transcribed cleanly. That call is mine,
  section by section.
- Never abandon a section silently. Never iterate more than once on
  unreadable math without checking in.

---

## Note format

Gist first. Under ~100 words. If it needs scrolling, it has failed.

```markdown
---
title: Principle of least action
tags: [physics, mechanics]
status: seed
---

**Gist:** Nature picks the path that minimizes the action integral.

**Why it matters:** Reframes mechanics from forces to optimization —
the Lagrangian formulation follows from this.

**Detail:** [[sources/2026-09-08-lagrangian.pdf|Lecture 3, p.4]]

**Related:** [[Euler-Lagrange equation]], [[Generalized coordinates]]
```

- `status`: `seed` / `growing` / `stable`. A stub is a valid note.
- Every note links its source PDF with a page number at the top.
- Every note links to at least one section index.
- Open with plain language before any math.
- A note about a diagram should show the diagram. Redraw it as inline
  SVG with `currentColor` strokes so it follows both themes, caption it
  as schematic, and leave `**Detail:**` pointing at the PDF as the
  authority on the exact shape.
- Unresolved questions become `> [!question]` callouts. An open
  question is a valid note state.

---

## Interview

- After the concepts are confirmed, ask **one** question, once per
  lecture, not per concept:
  *"What did you take away from this lecture?"*
- Put the answer in `## What I learned` in **my own words**, whole, in
  the lecture index note — one answer per lecture, one lecture note per
  lecture. Never split it across concept notes, even when it covers
  several of them: splitting sentences is not allowed.
- Write gist, significance, structure and links yourself.
- Never add your own content to `## What I learned`. If I skip the
  question, leave the section out entirely.
- Never invent a connection or example on my behalf.

### Editing my words

English is not my first language. **Fix mechanics, never substance.**

Allowed:
- spelling, typos, punctuation
- verb tense, articles, plurals, word order — the minimum to make a
  sentence grammatical

Not allowed:
- changing word choice, even to a "better" word
- making it more formal, more technical, or more polished
- reordering, merging, or splitting sentences
- removing hedges — "I think", "sort of", "not sure but" all stay.
  They record how confident I was, which is information.
- adding, expanding, or completing a half-finished thought
- correcting the physics. If I wrote something wrong, keep it and
  add a separate `> [!warning]` below the section.

If a fix would change the meaning, or you can't tell what I meant,
**ask instead of guessing**.

---

## Naming and disambiguation

- Before creating a note, check whether the bare name already exists.
- Terms stay bare until a second sense actually appears.
  **Do not pre-disambiguate.**
- When a second sense shows up: rename the original to
  `Term (domain).md`, create `Term.md` as a short hub note listing each
  variant with one line, and update all inbound links.
- Use `aliases:` in frontmatter for alternate names — Quartz generates
  redirects from them.
- Use pipe syntax in prose so disambiguation stays invisible:
  `[[Entropy (information theory)|entropy]]`

---

## Linking

- Link to concepts not yet written. Broken wikilinks are **intentional
  placeholders**, not errors. Never remove one.
- When a new note is created, check whether existing broken links now
  resolve to it.
- Link across domains. Cross-domain connections are the point of a
  single repo.
- Do not restructure section index pages or MOCs without asking.

---

## Sources

- `content/sources/` is **append-only**. Never delete, edit, or rename
  a file there.
- Nest by domain: `content/sources/physics/`, `content/sources/valuation/`
- Filenames — lowercase, hyphens, never spaces:
  - series: `lecture-NN-topic-slug.pdf` (number assigned by you,
    zero-padded so it sorts past lecture 9)
  - standalone: `topic-slug.pdf`, no number
  - e.g. `content/sources/physics/lecture-02-1d-kinematics.pdf`
         `content/sources/physics/renormalization.pdf`
- `content/inbox/` empty means nothing is pending.
- The PDF is ground truth. Typed notes are derived artifacts.

---

## Corrections

- When I report an error, **re-read the linked source PDF before
  editing**. Do not fix from reasoning alone — the source may use a
  nonstandard convention deliberately.
- Remove the matching entry from `## Transcription flags` once resolved.
- Commit corrections separately from new lectures.

---

## Math

- **KaTeX-compatible only.** Quartz renders with KaTeX, which is
  stricter than Obsidian's MathJax. Exotic macros that work in Obsidian
  may silently fail on the site.
- Define symbols on first use. Always state units.
- Never invent derivation steps to fill a gap. Mark it:
  `> [!warning] gap — verify`

---

## Git

- Push directly to `main`. Do not open pull requests.
- One commit per lecture: PDF and notes together, so a bad
  transcription is a single `git revert`.
- Show the diff and wait before committing.

---

## Upstream Quartz

This repo is a fork of Quartz. `content/` and `CLAUDE.md` are ours;
`quartz/`, `docs/` and `package.json` are upstream's. Pulling a new
Quartz version can conflict on any file both sides changed, and a
conflict resolved in upstream's favour drops our change silently.

- `quartz.config.yaml` is ours to edit — upstream maintains
  `quartz.config.default.yaml`. Prefer config over patching `quartz/`.
- When a change to `quartz/` is unavoidable, add an assertion to
  `scripts/check-site-invariants.sh`. It runs in CI after the build,
  so a silent revert fails the deploy instead of going unnoticed.
- Assert the outcome, not the diff — the rendered page, not a line
  number.

---

## Scope

Domain-specific conventions belong in `content/<domain>/CLAUDE.md`.
This file holds only what applies everywhere.
