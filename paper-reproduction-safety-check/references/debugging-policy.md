# Debugging Policy

Use this reference when a reproduction fails and the next action is unclear.

## Root-cause order

Check likely causes in roughly this order:

1. wrong command
2. wrong working directory
3. wrong Conda environment
4. missing dependency
5. incompatible Python / PyTorch / CUDA / compiler versions
6. wrong dataset path
7. invalid or incomplete dataset preprocessing
8. wrong config or scene-specific settings
9. wrong or incompatible checkpoint
10. GPU / CUDA / resource failure
11. repository bug or compatibility bug

The order is not absolute; use the traceback and repository code to prioritize evidence.

## Do not patch first

A source-code patch should not be the first response to errors such as:

- `ModuleNotFoundError`
- `FileNotFoundError`
- CUDA OOM
- device mismatch
- extension import failure
- shape mismatch

First determine whether the observed behavior can be explained by environment, data, command, config, or checkpoint state.

## Evidence collection examples

Environment:

```bash
conda env list
which python
python --version
python -m pip --version
```

PyTorch/CUDA:

```bash
python - <<'PY'
import torch
print("torch:", torch.__version__)
print("torch cuda:", torch.version.cuda)
print("cuda available:", torch.cuda.is_available())
PY
```

Processes and GPU:

```bash
nvidia-smi
ps -eo pid,etime,%cpu,%mem,cmd
```

Repository modifications:

```bash
git status --short
git diff
```

Tracebacks:

```bash
tail -100 <log-file>
```

## Source modification criteria

Recommend a code change only when:

1. the failure is reproducible,
2. the relevant code path has been inspected,
3. environment and data causes have been checked,
4. command/config/checkpoint causes have been checked,
5. there is evidence that the implementation or compatibility layer is actually the cause.

Before a patch, explain:

- file to change
- exact behavior being changed
- why it fixes the observed failure
- whether it changes the paper's intended method
- how to revert it

After a patch, inspect:

```bash
git diff
```

## Common failure patterns

### `ModuleNotFoundError`

Prioritize:

1. wrong active environment
2. package never installed
3. local CUDA extension not built
4. extension built against incompatible Python/PyTorch/CUDA

Do not immediately rewrite import statements.

### CUDA OOM

Check:

- whether another process owns memory
- requested GPU vs actual GPU
- scene-specific memory requirements
- batch/resolution/config differences
- whether resume is possible

Do not delete checkpoints or restart from zero before inspecting resume support.

### `FileNotFoundError`

Check:

- working directory
- config path construction
- dataset root
- scene name spelling
- preprocessing outputs
- relative vs absolute paths

Do not reinstall the environment for a missing data/config path error.

### Device mismatch

Check:

- tensor/model device creation
- checkpoint device restoration
- custom extension expectations
- explicit `.cuda()` or `.to(device)` calls
- multi-GPU visibility

Patch only after confirming the mismatch is produced by repository code rather than invocation/config state.

## Failure reporting

Prefer a compact diagnosis:

```text
Observed:
CUDA out of memory at iteration 18432

Confirmed:
- no training process remains
- latest valid checkpoint is iteration_18000
- official target is 30000
- repository supports --start_checkpoint

Likely root cause:
GPU memory exhaustion

Minimum safe next action:
inspect GPU occupancy and resume from iteration_18000 once the requested GPU is available
```

Separate facts from hypotheses and do not claim a fix has worked until its output is observed.
