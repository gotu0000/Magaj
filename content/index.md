---
title: Magaj
---

**Gist:** A typed index and recall layer over handwritten lecture notes.

The PDFs under `content/sources/` are the ground truth. These notes exist so a concept can be searched, linked and scanned in seconds — not to replace the source. If a note needs scrolling, it has failed.

## Sections

- [[physics/|Physics]] — concepts from the physics lectures.
- [[valuation/|Valuation]] — concepts from the valuation lectures.

## How this is arranged

- **Concepts** sit at the domain root. One note per concept, even when several courses cover it.
- **Lectures** sit in `<domain>/lectures/`. Thin index notes that point at concepts, never a monolithic write-up.
- **Sources** sit in `content/sources/<domain>/`. Append-only — the PDF stays ground truth.

Broken links are deliberate. They mark a concept that has come up but is not written yet.
