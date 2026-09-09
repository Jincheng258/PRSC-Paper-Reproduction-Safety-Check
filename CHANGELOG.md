# Changelog

All notable changes to PRSC — Paper Reproduction Safety Check — will be documented in this file.

The project follows semantic versioning for public releases where practical.

## [0.1.0] — 2026-09-09

### Added

- Initial public Agent Skill package under `paper-reproduction-safety-check/`.
- Standards-oriented `SKILL.md` with YAML frontmatter and version metadata.
- Safety-first reproduction audit workflow covering repository inspection, environments, datasets, preprocessing, GPUs, processes, logs, checkpoints, resume support, rendering, and evaluation.
- Explicit reproduction state model including `NOT_STARTED`, `TRAIN_INTERRUPTED`, `TRAIN_FINISHED`, `COMPLETE`, `FAILED`, and `UNKNOWN`.
- Progressive-disclosure references:
  - `references/reproduction-audit.md`
  - `references/debugging-policy.md`
  - `references/3dgs-reproduction-check.md`
- Reusable tmux-friendly multi-scene Bash pattern under `scripts/batch-safe-run.sh`.
- End-to-end dynamic Gaussian / DyNeRF example.
- Public README with installation guidance, safety rules, repository structure, and Mermaid workflow diagram.

### Fixed

- Removed literal Markdown fences accidentally embedded inside the Bash example.
- Removed the legacy root-level `SKILL.md` to avoid competing skill definitions.
- Clarified MIT licensing language.
- Reduced the core Skill size by moving detailed procedures into references.

### Safety principles established

- Inspect before executing.
- Reuse existing environments before creating new ones.
- Preserve existing logs, checkpoints, outputs, and local modifications.
- Verify checkpoints against official target iterations or epochs.
- Verify render and evaluation stages when required by the reproduction target.
- Diagnose environment, data, command, config, checkpoint, and GPU causes before patching source code.
- Avoid `set -e` and batch-level `exit` for independent multi-scene experiment batches by default.
