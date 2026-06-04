# `scenario/` — tool-specific seeds

Everything the tool needs that isn't the bare app goes here. The contents differ per
tool; this template provides only the parts common to all of them.

## Always present

- `versions/v2_init.py`, `versions/v3_init.py` — the v2.0.0 (even split) and v3.0.0
  (uneven split) implementations of `tipcalc/__init__.py`. `run_experiment.sh` copies
  these over `app/tipcalc/__init__.py` at the right life-cycle stage.

## Add per tool (examples)

- **towncrier / scriv / reno** — the `[tool.towncrier]` / `setup.cfg` / `reno` config
  to append to `pyproject.toml`, plus the news/change fragments to create at each stage
  (e.g. `fragments/stage2/`, `fragments/stage3/`).
- **keepachangelog / keepachangelog-manager** — a `CHANGELOG.seed.md` and the
  per-stage diffs to apply.
- **git-cliff / python-semantic-release** (later phases) — `cliff.toml` /
  `[tool.semantic_release]` config.

Keep it minimal. The app is intentionally trivial; the interesting bits are the tool
config and the per-stage change descriptions.
