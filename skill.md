# Paper Reproduction Safety Check

A reusable safety-first workflow for inspecting, diagnosing, continuing, and validating research-paper code reproductions.

This Skill is intended primarily for:

* 3D Gaussian Splatting
* 4D / Dynamic Gaussian Splatting
* NeRF
* Computer Vision
* Computer Graphics
* Robotics
* Deep Learning research repositories

The workflow may also be applied to other research codebases with environment setup, datasets, training, checkpoints, rendering, evaluation, and multi-stage experiments.

---

# Core Principle

Always follow:

```text
Inspect first.
Understand second.
Execute last.
```

Do not begin by reinstalling dependencies, modifying source code, deleting outputs, or launching full training.

The first objective is to determine:

```text
1. What does the official repository actually require?
2. What has already been completed on the current machine?
3. What is the minimum safe next action?
```

---

# 1. Default Behavior

When the user asks to:

* reproduce a paper,
* continue a previous reproduction,
* determine whether experiments have finished,
* debug a research repository,
* run additional scenes,
* render or evaluate existing checkpoints,
* inspect a partially completed server experiment,

first perform a reproduction audit.

Do not assume the repository is in a clean state.

Assume that the machine may already contain:

* existing Conda environments,
* partially installed dependencies,
* downloaded datasets,
* preprocessed datasets,
* modified configuration files,
* previous training runs,
* checkpoints,
* rendered outputs,
* evaluation results,
* logs,
* currently running processes,
* failed experiments,
* experiments belonging to other users.

Preserve existing evidence.

---

# 2. Required Inspection Order

Unless repository-specific evidence requires another order, inspect the reproduction in approximately this sequence:

```text
1. README / official instructions
2. Relevant source code
3. Repository state
4. Conda environments
5. Dependency compatibility
6. Dataset
7. Dataset preprocessing
8. GPU state
9. Running processes
10. Existing experiment directories
11. Logs
12. Checkpoints
13. Render outputs
14. Evaluation outputs
15. Determine reproduction status
16. Recommend minimum safe next action
```

Do not skip directly to training.

---

# 3. Read README and Source Code

The README is not sufficient evidence by itself.

Before determining the official pipeline, inspect the relevant implementation.

Depending on the repository, relevant files may include:

```text
README.md
train.py
render.py
eval.py
metrics.py
arguments/
configs/
scripts/
scene/
datasets/
dataset_readers.py
gaussian_model.py
trainer.py
utils/
```

Inspect enough code to determine:

* training entry point,
* argument parsing,
* config loading,
* dataset type selection,
* scene naming,
* dataset path expectations,
* preprocessing requirements,
* iteration count,
* checkpoint saving,
* checkpoint loading,
* resume behavior,
* render invocation,
* evaluation invocation,
* output directory structure,
* metric implementation,
* special scene-specific settings.

When README instructions conflict with source code, explicitly mention the discrepancy.

Prefer source-code evidence for actual execution behavior.

Do not guess.

---

# 4. Repository Inspection

Before modifying anything, inspect the current repository.

Useful checks include:

```bash
pwd
git status --short
git branch --show-current
git log -1 --oneline
```

Also inspect relevant files:

```bash
find . -maxdepth 2 -type f \
    \( \
        -name "README*" \
        -o -name "train*.py" \
        -o -name "render*.py" \
        -o -name "eval*.py" \
        -o -name "*.json" \
        -o -name "*.yaml" \
        -o -name "*.yml" \
    \) \
    | sort
```

Do not automatically run:

```bash
git pull
git reset --hard
git clean
```

These operations may destroy local modifications or change experiment behavior.

---

# 5. Environment Policy

The first environment-level inspection should normally include:

```bash
conda env list
```

Prefer reusing an existing environment.

Decision order:

```text
Existing compatible environment
        ↓
Reuse it

Existing environment with fixable missing package
        ↓
Diagnose first

Existing environment fundamentally incompatible
        ↓
Consider new environment
```

Do not automatically create a new environment simply because the README contains:

```bash
conda create ...
```

The server may already contain a correct environment.

---

# 6. Dependency Safety

Before installing or upgrading packages, inspect the current dependency state.

Possible checks:

```bash
python --version
which python
which pip

python - <<'PY'
import torch
print(torch.__version__)
print(torch.version.cuda)
print(torch.cuda.is_available())
PY
```

For repository-specific dependencies, test imports directly.

Example:

```bash
python - <<'PY'
mods = [
    "torch",
    "numpy",
]

for m in mods:
    try:
        mod = __import__(m)
        print(f"{m}: PASS")
    except Exception as e:
        print(f"{m}: FAIL -> {e}")
PY
```

Do not blindly run:

```bash
pip install -r requirements.txt
pip install --upgrade ...
conda install ...
```

until the current environment has been evaluated.

Avoid unnecessary upgrades to working environments.

---

# 7. Dataset Inspection

Verify that the dataset required by the repository actually exists and matches the loader assumptions.

Check:

* dataset root,
* scene directories,
* required metadata,
* image directories,
* video files,
* COLMAP outputs,
* pose files,
* train/test splits,
* preprocessing outputs,
* expected frame counts.

Example:

```bash
find /dataset/path/scene -maxdepth 2 -type d | sort
find /dataset/path/scene -maxdepth 2 -type f | head -100
```

Count files where useful:

```bash
find /dataset/path/scene/images -type f | wc -l
```

Do not assume a directory is valid merely because it exists.

Inspect repository dataset-loading code to determine required structure.

---

# 8. Preprocessing Inspection

Before rerunning preprocessing, determine whether it has already completed.

Look for repository-specific outputs such as:

```text
sparse/
images/
images_2/
colmap/
poses_bounds.npy
transforms_train.json
transforms_test.json
points3D.bin
cameras.bin
images.bin
```

If preprocessing outputs exist, verify them before rerunning expensive preprocessing.

Do not overwrite valid COLMAP or preprocessing outputs unnecessarily.

---

# 9. GPU Inspection

Before starting training, inspect GPUs.

Use:

```bash
nvidia-smi
```

For a requested GPU:

```bash
nvidia-smi -i <GPU_ID> \
    --query-gpu=index,name,memory.used,memory.total,utilization.gpu,power.draw \
    --format=csv
```

Also inspect processes:

```bash
ps -eo pid,etime,%cpu,%mem,cmd
```

When useful:

```bash
nvidia-smi pmon
```

Do not assume low utilization means the GPU is available.

Check memory usage and running processes.

Respect the GPU requested by the user.

Do not silently move experiments to another GPU unless necessary and explicitly explained.

---

# 10. Running Process Inspection

Before deciding an experiment has stopped, inspect active processes.

Example:

```bash
ps -eo pid,etime,%cpu,%mem,cmd \
    | grep -E '[p]ython|[t]rain.py|[r]ender.py|[e]val'
```

Whenever possible, narrow the process search by:

* repository name,
* scene name,
* output path,
* config name.

Do not start duplicate training if the same experiment is already running.

---

# 11. Existing Experiment Inspection

Search for previous output directories before creating new experiments.

Possible directories:

```text
output/
outputs/
logs/
log/
checkpoints/
results/
experiments/
runs/
```

Inspect directory names and timestamps.

Do not assume the newest directory is necessarily the correct experiment.

Use config paths, dataset names, scene names, and logs to identify the intended run.

---

# 12. Log Inspection

Logs are primary evidence.

Inspect:

* latest log file,
* recent log tail,
* errors,
* completion messages,
* iteration counters,
* saved checkpoints,
* render progress,
* evaluation output.

Useful commands:

```bash
find . -type f \
    \( \
        -name "*.log" \
        -o -name "*.out" \
        -o -name "*.txt" \
    \) \
    | sort
```

Latest log:

```bash
LOG=$(find logs \
    -type f \
    -name "*.log" \
    -printf "%T@ %p\n" \
    2>/dev/null \
    | sort -nr \
    | head -1 \
    | cut -d' ' -f2-)

echo "LOG=$LOG"

if [ -n "$LOG" ]; then
    tail -100 "$LOG"
fi
```

Search for likely errors:

```bash
grep -RniE \
    "Traceback|Error|Exception|CUDA out of memory|Killed|Segmentation fault|FAILED" \
    logs \
    2>/dev/null
```

Do not rely only on the final line of a log.

Some experiments may save valid checkpoints before a later render or evaluation failure.

---

# 13. Checkpoint Inspection

Determine:

```text
Does a checkpoint exist?
```

and separately:

```text
Does the checkpoint correspond to the official target iteration?
```

Example:

```bash
find . -type f \
    \( \
        -name "*.pth" \
        -o -name "*.pt" \
        -o -name "*.ckpt" \
        -o -name "point_cloud.ply" \
    \) \
    | sort
```

Example interpretation:

```text
Official target:
30000 iterations

Existing:
iteration_7000
iteration_12000
```

Status:

```text
TRAIN_INTERRUPTED
```

not:

```text
TRAIN_FINISHED
```

Always derive the expected target iteration from:

* official config,
* README,
* training script,
* scene-specific config.

---

# 14. Resume Inspection

Before restarting from zero, inspect whether the repository supports resume.

Search for:

```text
checkpoint
resume
load
start_checkpoint
iteration
restore
```

Example:

```bash
grep -RniE \
    "resume|checkpoint|load.*checkpoint|restore" \
    . \
    --include="*.py" \
    --include="*.sh" \
    --include="*.yaml" \
    --include="*.yml" \
    --include="*.json"
```

If safe resume is supported, prefer resume over restarting.

Do not invent resume arguments.

Confirm them from source code.

---

# 15. Render Inspection

Training completion does not imply reproduction completion.

Inspect whether rendering has been performed.

Check likely directories:

```text
render/
renders/
test/
train/
ours_30000/
video/
```

Count output frames when meaningful:

```bash
find <render_dir> \
    -type f \
    \( \
        -name "*.png" \
        -o -name "*.jpg" \
        -o -name "*.jpeg" \
    \) \
    | wc -l
```

Compare the count with the expected number of views or frames.

A render directory containing only a few images may indicate an interrupted render.

---

# 16. Evaluation Inspection

Inspect official evaluation outputs.

Possible metrics include:

```text
PSNR
SSIM
LPIPS
FPS
Storage
Model size
Training time
Rendering time
```

Search:

```bash
grep -RniE \
    "PSNR|SSIM|LPIPS|FPS" \
    output logs results \
    2>/dev/null
```

Also inspect:

```text
*.json
*.csv
metrics.txt
results.txt
```

Use the repository's official metric implementation whenever the goal is paper reproduction.

Do not substitute a different LPIPS backbone, image preprocessing convention, or evaluation split without making the difference explicit.

---

# 17. Reproduction State Classification

For each scene or experiment, classify the state.

Use these states when appropriate:

```text
NOT_STARTED
ENV_ERROR
DATA_ERROR
PREPROCESSING
TRAINING
TRAIN_INTERRUPTED
TRAIN_FINISHED
RENDERING
RENDER_FINISHED
EVALUATING
EVAL_FINISHED
COMPLETE
FAILED
UNKNOWN
```

Example summary:

```text
scene                 train          render        eval          status
---------------------------------------------------------------------------
coffee_martini        30000/30000    complete      complete      COMPLETE
cook_spinach          30000/30000    missing       missing       TRAIN_FINISHED
cut_roasted_beef      12000/30000    missing       missing       TRAIN_INTERRUPTED
flame_salmon_1        30000/30000    complete      complete      COMPLETE
flame_steak           not started    -              -             NOT_STARTED
sear_steak            failed         -              -             FAILED
```

Do not collapse all scenes into a single vague status.

---

# 18. Required Diagnostic Output

After the inspection phase, provide the user with four things.

## A. Current state

Explain exactly what is already complete.

Example:

```text
Environment:
PASS

Dataset:
6 / 6 scenes present

Training:
3 complete
1 interrupted
1 not started
1 failed

Rendering:
2 complete

Evaluation:
2 complete
```

---

## B. Official pipeline

Explain the repository pipeline based on actual code.

Example:

```text
dataset
  ↓
train.py
  ↓
checkpoint
  ↓
render.py
  ↓
metrics.py
```

Mention important file paths and entry points.

---

## C. Missing work

Identify only the stages that remain.

Example:

```text
cook_spinach:
render + evaluation

cut_roasted_beef:
resume training → render → evaluation

flame_steak:
train → render → evaluation

sear_steak:
diagnose failure before retrying
```

---

## D. Minimum safe next action

Prefer the smallest useful next command.

Do not immediately provide a full multi-hour training script if a smaller diagnostic check is still needed.

---

# 19. Error Diagnosis

When an experiment fails, do not immediately patch source code.

First classify likely causes.

Recommended order:

```text
1. Wrong command
2. Wrong working directory
3. Wrong environment
4. Missing dependency
5. Version mismatch
6. Wrong dataset path
7. Dataset preprocessing issue
8. Wrong config
9. Wrong checkpoint
10. GPU / CUDA problem
11. Repository bug
```

For each candidate, gather evidence.

Example:

```text
Observed:
ModuleNotFoundError: diff_gaussian_rasterization

Possible causes:
1. wrong Conda environment
2. extension not compiled
3. extension compiled for another Python/CUDA version

Next check:
which python
conda env list
pip show ...
find submodules ...
```

Do not patch code when environment mismatch is the likely root cause.

---

# 20. Source Code Modification Policy

Default:

```text
Do not modify source code.
```

Only recommend a code patch when:

1. the error is reproducible,
2. environment and data issues have been ruled out,
3. the relevant source code has been inspected,
4. there is evidence of a repository bug or compatibility issue,
5. the change is minimal and explainable.

Before modifying, explain:

```text
what will change
why it is necessary
which file is affected
whether behavior differs from the paper
how to revert it
```

Prefer backing up changed files or using Git diff.

After modifying:

```bash
git diff
```

should be inspected.

---

# 21. Destructive Command Policy

Avoid destructive commands unless explicitly necessary and clearly justified.

Do not casually use:

```bash
rm -rf
git reset --hard
git clean -fd
conda remove
pip uninstall
```

Never delete previous experiment results simply to make the directory cleaner.

Old outputs and logs are debugging evidence.

---

# 22. Batch Bash Policy

For multi-scene research experiments, scripts should normally:

* be compatible with tmux,
* save logs,
* clearly print scene names,
* clearly print SUCCESS / FAILED,
* continue after a single scene fails,
* avoid terminating the full batch unnecessarily.

Do not default to:

```bash
set -e
```

Do not use:

```bash
exit
```

to terminate the full batch after one scene fails.

Preferred structure:

```bash
SCENES=(
    scene_1
    scene_2
    scene_3
)

mkdir -p logs

for scene in "${SCENES[@]}"; do

    echo
    echo "============================================================"
    echo "START: $scene"
    echo "============================================================"

    python train.py \
        ... \
        2>&1 | tee "logs/${scene}.log"

    status=${PIPESTATUS[0]}

    if [ "$status" -ne 0 ]; then
        echo
        echo "============================================================"
        echo "FAILED: $scene"
        echo "EXIT CODE: $status"
        echo "============================================================"

        continue
    fi

    echo
    echo "============================================================"
    echo "SUCCESS: $scene"
    echo "============================================================"

done

echo
echo "============================================================"
echo "BATCH FINISHED"
echo "============================================================"
```

When training, rendering, and evaluation are separate stages, handle each stage explicitly.

---

# 23. tmux Policy

Long experiments should be easy to run inside tmux.

Recommended:

```bash
tmux new -s reproduction
```

Use `tee` for logs:

```bash
python train.py ... 2>&1 | tee logs/train.log
```

Avoid commands that depend on an interactive SSH session remaining connected.

---

# 24. Multi-Stage Batch Policy

For pipelines such as:

```text
train
↓
render
↓
evaluate
```

do not run later stages when an earlier required stage failed.

Example:

```bash
python train.py ... 2>&1 | tee "$TRAIN_LOG"
train_status=${PIPESTATUS[0]}

if [ "$train_status" -ne 0 ]; then
    echo "TRAIN FAILED"
    continue
fi

python render.py ... 2>&1 | tee "$RENDER_LOG"
render_status=${PIPESTATUS[0]}

if [ "$render_status" -ne 0 ]; then
    echo "RENDER FAILED"
    continue
fi

python metrics.py ... 2>&1 | tee "$EVAL_LOG"
eval_status=${PIPESTATUS[0]}

if [ "$eval_status" -ne 0 ]; then
    echo "EVAL FAILED"
    continue
fi

echo "COMPLETE"
```

This preserves failure isolation while preventing invalid downstream stages.

---

# 25. Existing Result Preservation

Never overwrite an existing experiment without checking it first.

If a new experiment is needed, prefer a new output name.

Example:

```text
output/coffee_martini
```

already exists.

Prefer:

```text
output/coffee_martini_retry_20260909
```

or another meaningful run name when a separate rerun is necessary.

However, if the repository supports correct resume into the existing output directory, inspect that mechanism first.

---

# 26. User Execution Model

Unless the environment allows direct server execution, prefer this interaction loop:

```text
Assistant
   ↓
inspect repository / reason
   ↓
provide safe diagnostic command
   ↓
User executes command
   ↓
User returns raw output
   ↓
Assistant analyzes evidence
   ↓
provide next minimum command
```

Do not pretend a command has been run if only the user can run it.

Do not infer success from commands that were merely proposed.

---

# 27. Raw Output Preference

When diagnosing a reproduction, prefer raw terminal output over summarized descriptions.

Ask the user to provide:

```text
full traceback
log tail
nvidia-smi output
checkpoint listing
directory listing
metric files
```

when needed.

Do not rely on:

```text
"It seems to have failed."
```

if raw logs are available.

---

# 28. Evidence-Based Conclusions

Use evidence-specific language.

Prefer:

```text
The latest checkpoint is iteration_12000 while the official config targets 30000, so training is incomplete.
```

Avoid:

```text
It probably hasn't finished.
```

Prefer:

```text
No training process is currently running, and the last log ends with a CUDA OOM at iteration 18432.
```

Avoid:

```text
The process seems dead.
```

---

# 29. Completion Criteria

Do not declare:

```text
REPRODUCTION COMPLETE
```

only because training stopped successfully.

Completion should match the user's target.

For a standard quantitative paper reproduction, normally verify:

```text
[ ] correct environment
[ ] correct dataset
[ ] preprocessing complete
[ ] target training iteration reached
[ ] checkpoint exists
[ ] rendering complete
[ ] expected frame/view count present
[ ] official evaluation complete
[ ] metrics saved
[ ] no unresolved fatal errors
```

If the user's goal is only training, completion may stop earlier.

Always align completion criteria with the user's requested target.

---

# 30. Paper Number Comparison

When the user wants to compare reproduced metrics against paper values:

1. identify the exact dataset,
2. identify the exact scene,
3. identify the exact train/test protocol,
4. identify evaluation metric implementation,
5. identify LPIPS backbone if relevant,
6. identify resolution,
7. identify compression level or model variant,
8. identify whether values are per-scene or averaged.

Do not compare incompatible numbers as if they were equivalent.

---

# 31. Common 3DGS / 4DGS Checks

For Gaussian Splatting repositories, commonly inspect:

```text
point_cloud/
iteration_*/
point_cloud.ply
cfg_args
cameras.json
deformation/
chkpnt*.pth
```

Potential rendering directories:

```text
train/
test/
ours_*/
renders/
gt/
```

Potential evaluation files:

```text
results.json
per_view.json
metrics.json
```

Also inspect custom CUDA extensions such as:

```text
diff-gaussian-rasterization
simple-knn
tiny-cuda-nn
gridencoder
```

Verify import and compilation compatibility before rebuilding.

---

# 32. Dynamic Scene Checks

For dynamic-scene repositories, additionally inspect:

* frame count,
* camera count,
* timestamp handling,
* temporal normalization,
* scene-specific configuration,
* deformation checkpoint,
* static/dynamic stages,
* warmup stages,
* multi-stage compression,
* temporal evaluation protocol.

Do not assume all scenes share identical hyperparameters.

Inspect scene-specific configs.

---

# 33. Status Summary Template

Use a concise table when possible:

```text
scene                 env   data   train        render   eval   status
---------------------------------------------------------------------------
coffee_martini        OK    OK     30000/30000  YES      YES    COMPLETE
cook_spinach          OK    OK     30000/30000  NO       NO     TRAIN_FINISHED
cut_roasted_beef      OK    OK     12000/30000  NO       NO     TRAIN_INTERRUPTED
flame_salmon_1        OK    OK     30000/30000  YES      YES    COMPLETE
flame_steak           OK    OK     0/30000      NO       NO     NOT_STARTED
sear_steak            OK    OK     FAILED       NO       NO     FAILED
```

Follow with:

```text
What remains:
- cook_spinach: render + eval
- cut_roasted_beef: resume from checkpoint
- flame_steak: start training
- sear_steak: diagnose error
```

---

# 34. Safe First-Pass Audit Template

For an unknown repository, a useful first-pass terminal audit is:

```bash
echo "================================================================"
echo "1. CURRENT DIRECTORY"
echo "================================================================"

pwd

echo
echo "================================================================"
echo "2. CONDA ENVIRONMENTS"
echo "================================================================"

conda env list

echo
echo "================================================================"
echo "3. REPOSITORY STATUS"
echo "================================================================"

git status --short 2>/dev/null
git log -1 --oneline 2>/dev/null

echo
echo "================================================================"
echo "4. GPU STATUS"
echo "================================================================"

nvidia-smi

echo
echo "================================================================"
echo "5. PYTHON PROCESSES"
echo "================================================================"

ps -eo pid,etime,%cpu,%mem,cmd \
    | grep -E '[p]ython|[t]rain|[r]ender|[e]val'

echo
echo "================================================================"
echo "6. IMPORTANT FILES"
echo "================================================================"

find . -maxdepth 2 -type f \
    \( \
        -name "README*" \
        -o -name "train*.py" \
        -o -name "render*.py" \
        -o -name "eval*.py" \
        -o -name "*.yaml" \
        -o -name "*.yml" \
        -o -name "*.json" \
    \) \
    2>/dev/null \
    | sort \
    | head -200

echo
echo "================================================================"
echo "DONE"
echo "================================================================"
```

This is an inspection command, not a training command.

---

# 35. Commands to Avoid by Default

Do not use these automatically:

```bash
set -e
exit
rm -rf
git reset --hard
git clean -fd
pip install --upgrade
conda remove
kill -9
pkill python
```

They may be appropriate in specific situations, but require evidence and justification.

---

# 36. Communication Style

When working with the user:

* explain why each major check is needed,
* distinguish confirmed facts from hypotheses,
* show the current reproduction state clearly,
* avoid overwhelming the user with unnecessary commands,
* prefer one meaningful diagnostic step over many speculative changes,
* preserve reproducibility.

When a command is provided, make clear whether it is:

```text
READ-ONLY CHECK
SAFE FIX
TRAINING
RENDERING
EVALUATION
DESTRUCTIVE
```

when that distinction materially helps.

---

# 37. Final Objective

The goal is not merely to make a command run.

The goal is to establish a reliable reproduction state:

```text
Repository understood
        +
Environment verified
        +
Dataset verified
        +
Experiment state audited
        +
Failures diagnosed
        +
Missing stages executed
        +
Outputs validated
        =
Reliable Reproduction
```

---

# Golden Rule

> Never restart a reproduction experiment before understanding its current state.

And always remember:

> **Inspect first. Understand second. Execute last.**
