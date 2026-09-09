---
name: paper-reproduction-safety-check
description: Safety-first workflow for auditing, continuing, debugging, and validating research-paper code reproductions. Use when a user wants to reproduce or resume a research repository, determine current experiment progress, inspect Conda environments, datasets, GPUs, logs, checkpoints, renders, evaluations, or plan safe multi-scene training without blindly reinstalling, patching, deleting, or restarting work.
license: MIT
metadata:
  author: Jincheng258
  version: "0.1.0"
---

# Paper Reproduction Safety Check

Use this skill to inspect a research-code reproduction before changing its state.

Core rule:

> Inspect first. Understand second. Execute last.

The goal is not merely to make a command run. The goal is to establish what the repository requires, what has already happened on the machine, what evidence supports that conclusion, and what the minimum safe next action is.

## Default operating mode

When the user asks to reproduce, continue, debug, render, evaluate, or check whether a research experiment has finished:

1. Audit before executing.
2. Preserve existing environments, outputs, checkpoints, logs, and local modifications.
3. Treat README instructions as guidance, not the only source of truth.
4. Inspect relevant source code before deciding the official pipeline.
5. Prefer existing compatible Conda environments.
6. Prefer resume over restart when resume is supported and valid.
7. Do not call training complete just because a checkpoint exists.
8. Do not call reproduction complete just because training ended.
9. Do not patch source code until environment, data, command, config, and checkpoint causes have been checked.
10. For batch work, isolate failures so one scene does not terminate unrelated scenes.

## Required inspection order

Use this order unless repository-specific evidence clearly requires another:

1. README and official instructions.
2. Relevant source code.
3. Repository state and local modifications.
4. Conda environments and Python/CUDA compatibility.
5. Dataset and preprocessing.
6. GPU state and running processes.
7. Existing experiment directories.
8. Logs.
9. Checkpoints and resume support.
10. Render outputs.
11. Evaluation outputs and metric implementation.
12. Per-scene reproduction state.
13. Minimum safe next action.

For a detailed checklist, read `references/reproduction-audit.md`.

## 1. Understand the repository first

Inspect enough implementation to identify the real execution path. Relevant files commonly include:

- `README.md`
- training entry points such as `train.py`
- render entry points such as `render.py`
- metric/evaluation code
- argument parsers
- config loaders
- dataset readers
- checkpoint save/load code
- resume logic
- scene-specific configs
- shell scripts used by the authors

Determine, from code where possible:

- training entry point and arguments
- dataset type and expected directory layout
- preprocessing requirements
- target iterations or epochs
- checkpoint naming and save locations
- checkpoint loading/resume behavior
- render entry point and expected model iteration
- evaluation entry point and metrics
- output directory conventions
- scene-specific overrides

If README and source code disagree, state the discrepancy explicitly and use source-code behavior as the execution authority unless there is stronger evidence.

Do not guess missing arguments or resume flags.

## 2. Inspect repository state before changing files

Useful read-only checks include:

```bash
pwd
git status --short
git branch --show-current
git log -1 --oneline
```

Do not automatically run destructive Git commands such as:

```bash
git reset --hard
git clean -fd
```

A local config change may be intentional experiment evidence.

## 3. Reuse environments first

The first environment-level check should normally include:

```bash
conda env list
```

Then inspect the candidate environment before installing anything:

```bash
which python
python --version

python - <<'PY'
import torch
print("torch:", torch.__version__)
print("torch cuda:", torch.version.cuda)
print("cuda available:", torch.cuda.is_available())
PY
```

Decision order:

- compatible existing environment -> reuse it
- mostly compatible environment with a specific missing dependency -> diagnose before changing
- fundamentally incompatible environment -> only then consider a new environment

Do not blindly run `pip install -r requirements.txt`, package upgrades, or a new `conda create` merely because the README contains those commands.

## 4. Validate data and preprocessing

Verify the dataset against the repository's actual loader assumptions.

Check as applicable:

- dataset root
- scene directories
- images or videos
- camera metadata
- poses
- train/test split
- COLMAP outputs
- point clouds
- preprocessing artifacts
- expected frame/view counts

A directory existing is not enough to prove the dataset is valid.

Before rerunning preprocessing, inspect whether valid outputs already exist. Avoid overwriting expensive COLMAP or preprocessing results without evidence that they are wrong.

## 5. Inspect GPU and processes

Before starting a job, inspect current GPU use and processes:

```bash
nvidia-smi
ps -eo pid,etime,%cpu,%mem,cmd
```

For a requested GPU:

```bash
nvidia-smi -i <GPU_ID> \
  --query-gpu=index,name,memory.used,memory.total,utilization.gpu,power.draw \
  --format=csv
```

Respect the user's requested GPU. Do not silently move work to another device. Do not start duplicate training if the same run is already active.

## 6. Treat logs as primary evidence

Inspect recent logs for:

- iteration/epoch progress
- successful completion markers
- checkpoint saves
- tracebacks
- CUDA OOM
- killed processes
- missing files
- device mismatches
- render failures
- evaluation failures

Do not infer success from the existence of an output directory alone.

Prefer raw terminal output and log tails over paraphrased reports when diagnosing failures.

## 7. Verify checkpoints against the official target

Separate these questions:

1. Does a checkpoint exist?
2. Does it represent the official target iteration/epoch?

Example:

```text
Official target: 30000
Latest checkpoint: iteration_12000
```

This is `TRAIN_INTERRUPTED`, not `TRAIN_FINISHED`.

Derive the target from the repository's config, README, training script, or scene-specific config.

## 8. Inspect resume support before restarting

Search implementation for concepts such as:

```text
resume
checkpoint
restore
start_checkpoint
load_checkpoint
iteration
```

If the repository supports safe resume and the checkpoint is compatible, prefer resume over restarting from zero.

Never invent a resume flag from memory.

## 9. Training is not full reproduction

Unless the user's target is explicitly training-only, inspect downstream stages:

```text
train -> render -> evaluate
```

For rendering, verify that the expected model iteration was used and that output frame/view counts are plausible.

For evaluation, prefer the repository's official implementation. Check details that can change comparability, such as:

- train/test split
- image resolution
- LPIPS backbone
- preprocessing convention
- model variant
- compression level
- per-scene vs averaged metrics

## 10. Classify each scene explicitly

Use evidence-based states such as:

- `NOT_STARTED`
- `ENV_ERROR`
- `DATA_ERROR`
- `PREPROCESSING`
- `TRAINING`
- `TRAIN_INTERRUPTED`
- `TRAIN_FINISHED`
- `RENDERING`
- `RENDER_FINISHED`
- `EVALUATING`
- `EVAL_FINISHED`
- `COMPLETE`
- `FAILED`
- `UNKNOWN`

Do not collapse a multi-scene experiment into one vague status.

A useful summary format is:

```text
scene                 train          render   eval   status
--------------------------------------------------------------
coffee_martini        30000/30000    YES      YES    COMPLETE
cook_spinach          30000/30000    NO       NO     TRAIN_FINISHED
cut_roasted_beef      12000/30000    NO       NO     TRAIN_INTERRUPTED
```

## 11. Report four things after an audit

Before proposing major execution, report:

### Current state

State what is confirmed complete, incomplete, active, failed, or unknown.

### Official pipeline

Show the repository's actual flow and important entry points.

### Missing work

Identify only the stages that remain for each scene/run.

### Minimum safe next action

Give the smallest command or check that resolves the next uncertainty or completes the next missing stage.

Avoid giving a large multi-hour script when one diagnostic command is still needed.

## 12. Diagnose failures before patching

Check likely causes in roughly this order:

1. wrong command or working directory
2. wrong environment
3. missing dependency
4. dependency/version mismatch
5. wrong dataset path or structure
6. preprocessing issue
7. wrong config
8. wrong/incompatible checkpoint
9. GPU/CUDA/resource problem
10. repository bug

For detailed debugging rules, read `references/debugging-policy.md`.

Only recommend a source patch when evidence shows it is needed. Explain what changes, why it is necessary, whether it changes paper behavior, and how to revert it.

## 13. Avoid destructive actions by default

Do not casually use:

```bash
rm -rf
git reset --hard
git clean -fd
conda remove
pip uninstall
kill -9
pkill python
```

Old outputs and logs are debugging evidence.

When a new run is necessary, prefer a new meaningful output path unless correct resume requires the existing one.

## 14. Safe batch Bash policy

For multiple independent scenes, scripts should normally:

- work inside `tmux`
- save logs with `tee`
- print the current scene and stage
- capture the real command exit status when piped through `tee`
- print `SUCCESS` / `FAILED`
- use `continue` for scene-level failure
- avoid `set -e`
- avoid batch-level `exit` after a single-scene failure
- skip downstream render/evaluation when a required upstream stage failed

Use `scripts/batch-safe-run.sh` as the reusable pattern. Adapt its repository-specific arguments only after inspecting source code.

## 15. Completion criteria

Align completion with the user's target.

For a normal quantitative reproduction, do not report `COMPLETE` until the required items are verified, typically:

- correct environment
- correct dataset and preprocessing
- target training iteration/epoch reached
- expected checkpoint present
- render complete
- expected output count present
- official evaluation complete
- metrics saved
- no unresolved fatal errors

If the user's goal is only training, stop at training completion and say that render/evaluation were outside scope.

## 16. Evidence language

Prefer:

> The latest checkpoint is iteration_12000 while the scene config targets 30000, so training is incomplete.

Avoid:

> It probably did not finish.

Prefer:

> No matching training process is active, and the latest log ends with CUDA OOM at iteration 18432.

Avoid:

> The process seems dead.

Clearly separate confirmed facts, hypotheses, and next checks.

## 17. Interaction model

When the assistant cannot directly access the user's server, use this loop:

```text
inspect repository -> provide read-only check -> user runs it -> analyze raw output -> provide minimum next action
```

Do not claim a proposed command was executed.

For an extended dynamic Gaussian example, read `references/3dgs-reproduction-check.md`.

## Final rule

Never restart a reproduction experiment before understanding its current state.
