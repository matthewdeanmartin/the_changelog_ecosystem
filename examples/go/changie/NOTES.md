# changie v1.24.0 — Experiment Notes

**Date:** 2026-06-02
**Image:** `cle-exp-changie` (debian:bookworm-slim + changie 1.24.0)
**Scenario:** Shell tip-calculator, three releases (v1.0.0 → v2.0.0 → v3.0.0)

---

## Full Transcript

```
changie version:
changie version v1.24.0

==================== STAGE 1: v1.0.0 code, NO changelog ====================

program output:
Bill: $80.00  Tip (18%): $14.40  Total: $94.40
(no CHANGELOG.md yet)

==================== STAGE 2: changie init, add fragment, batch v1.0.0 ====================

--- changie batch v1.0.0 ---
--- .changes/v1.0.0.md ---
## v1.0.0 - 2026-06-02
### Added
- Compute tip for a restaurant bill at 18% rate and print total--- changie merge ---
----- CHANGELOG.md -----
## v1.0.0 - 2026-06-02
### Added
- Compute tip for a restaurant bill at 18% rate and print total------------------------

==================== STAGE 3: implement even split, add fragment ====================

program output:
Bill: $80.00  Tip: $14.40  Total: $94.40
Split evenly among 4: $23.60 each
----- CHANGELOG.md -----
## v1.0.0 - 2026-06-02
### Added
- Compute tip for a restaurant bill at 18% rate and print total------------------------

==================== STAGE 4a: batch + merge for v2.0.0 ====================

## v2.0.0 - 2026-06-02
### Added
- Split the bill evenly among 4 diners----- CHANGELOG.md -----
## v2.0.0 - 2026-06-02
### Added
- Split the bill evenly among 4 diners## v1.0.0 - 2026-06-02
### Added
- Compute tip for a restaurant bill at 18% rate and print total------------------------

==================== STAGE 4b: implement uneven split, add fragment, batch + merge v3.0.0 ====================

program output:
Bill: $80.00  Total with tip: $94.40
  Ada: $35.40 (weight 3)
  Linus: $23.60 (weight 2)
  Grace: $35.40 (weight 3)
  Dennis: $23.60 (weight 2)
----- CHANGELOG.md -----
## v3.0.0 - 2026-06-02
### Added
- Split the bill unevenly by per-person weights (Ada:3, Linus:2, Grace:3, Dennis:2) — output format changed## v2.0.0 - 2026-06-02
### Added
- Split the bill evenly among 4 diners## v1.0.0 - 2026-06-02
### Added
- Compute tip for a restaurant bill at 18% rate and print total------------------------

==================== DONE — copying artifacts to out/ ====================

Artifacts in /work/out:
total 12
drwxrwxrwx 1 root root 4096 Jun  2 13:31 .
drwxr-xr-x 1 root root 4096 Jun  2 13:31 ..
-rw-r--r-- 1 root root  309 Jun  2 13:31 CHANGELOG.md
-rw-r--r-- 1 root root  338 Jun  2 13:31 git-log.txt
-rw-r--r-- 1 root root   21 Jun  2 13:31 git-tags.txt
-rw-r--r-- 1 root root 2046 Jun  2 13:31 transcript.txt
```

---

## Final CHANGELOG.md (out/CHANGELOG.md)

```
## v3.0.0 - 2026-06-02
### Added
- Split the bill unevenly by per-person weights (Ada:3, Linus:2, Grace:3, Dennis:2) — output format changed## v2.0.0 - 2026-06-02
### Added
- Split the bill evenly among 4 diners## v1.0.0 - 2026-06-02
### Added
- Compute tip for a restaurant bill at 18% rate and print total
```

## Git log (out/git-log.txt)

```
8b47ea5 (HEAD -> master, tag: v3.0.0) chore(release): 3.0.0
dce544e feat!: split the bill unevenly by weight
634640a (tag: v2.0.0) chore(release): 2.0.0
5205078 feat: split the bill evenly among diners
91d83db (tag: v1.0.0) chore(release): 1.0.0
63a8ad1 docs: add changelog fragment for v1.0.0
8569946 feat: compute tip for a single bill
```

---

## Observations

### What worked without friction

- `changie init` ran cleanly and created `.changes/unreleased/` immediately.
- Copying a pre-written `.changie.yaml` over the default was accepted without complaint.
- Fragment yaml (`kind:` / `body:`) matched the expected schema exactly; no schema errors.
- `changie batch v1.0.0` picked up `.yaml` files from `.changes/unreleased/`, created
  `.changes/v1.0.0.md`, and removed the source fragments in one step.
- `changie merge` prepended the newest version at the top of `CHANGELOG.md` correctly on
  every subsequent run — newest-first ordering was automatic.
- Three full release cycles (v1→v2→v3) ran end-to-end without a single error.

### Rough edges found

1. **No trailing newline between version sections.** The merged `CHANGELOG.md` has no blank
   line between version blocks. Each section ends with the last bullet and immediately flows
   into the next `##` heading. This makes the file hard to read in raw form and would fail
   most Markdown linters. The `versionFormat` template has no trailing newline, and the merge
   step does not add one. A workaround is to add `\n` at the end of `versionFormat`, but the
   docs do not mention this.

2. **`changie init` creates its own `.changie.yaml`.** When we then `cp` our custom config
   over it the overwrite is silent and works, but the sequence is slightly awkward. There is
   no `changie init --config` flag to specify a template file.

3. **Fragment files must be copied manually for automation.** The normal contributor path is
   `changie new`, which launches an interactive prompt. In CI or scripted scenarios you must
   drop pre-written `.yaml` files into the unreleased directory yourself — there is no
   `changie new --kind Added --body "..."` non-interactive flag in v1.24.0.

4. **No built-in breaking-change signal in the fragment schema.** To note a breaking change
   we embedded the note in the body text. There is no `breaking: true` field or equivalent
   that changie natively understands or styles differently in the output.

### Config details that mattered

The `versionFormat` template uses Go's `time.Format` with the reference date `2006-01-02`;
getting this wrong (e.g. `YYYY-MM-DD`) produces no error but garbled dates. The config
key is `versionFormat`, not `version_format` — snake_case keys are silently ignored.
