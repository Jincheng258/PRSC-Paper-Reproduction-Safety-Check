# End-to-End Example: Dynamic Gaussian Reproduction Audit

This example demonstrates how `paper-reproduction-safety-check` should behave when a user wants to continue a partially completed dynamic Gaussian Splatting reproduction.

The repository, paths, and results in this example are fictional but intentionally realistic.

---

# Scenario

A user previously worked on a dynamic Gaussian Splatting repository but no longer remembers which scenes finished successfully.

The target dataset is DyNeRF.

The user does **not** want the assistant to reinstall environments or restart everything blindly.

---

# User Prompt

```text
I am reproducing this repository:

https://github.com/example-lab/DynamicGaussian

Repository path:

/data/6001_project/DynamicGaussian

Dataset path:

/dataset/dynerf

I want to reproduce these DyNeRF scenes:

coffee_martini
cook_spinach
cut_roasted_beef
flame_salmon_1
flame_steak
sear_steak

I worked on this project before, but I do not remember exactly
which scenes completed.

Please first inspect the README and all source code relevant to
training, dataset loading, rendering, checkpoints, and evaluation.

Then determine my current state.

Check:

- Conda environments
- dependencies
- dataset
- preprocessing
- GPU
- running processes
- existing outputs
- logs
- checkpoints
- renders
- evaluation metrics

Preferred GPU:

GPU 4

Do not immediately:

- create another environment
- reinstall dependencies
- modify source code
- delete old experiments
- restart all training

If something still needs to run, give me tmux-friendly Bash.

A failed scene should not terminate the entire batch.

Do not use set -e or batch-level exit.
```

---

# Phase 1 — Understand the Official Repository Pipeline

The assistant should first inspect the repository documentation and relevant implementation.

Suppose the repository contains:

```text
DynamicGaussian/
├── README.md
├── train.py
├── render.py
├── metrics.py
├── arguments/
│   └── __init__.py
├── scene/
│   ├── __init__.py
│   ├── dataset_readers.py
│   └── gaussian_model.py
├── configs/
│   └── dynerf/
└── utils/
```

The README states:

```text
Training:

python train.py \
    -s <dataset> \
    -m <output> \
    --iterations 30000

Rendering:

python render.py \
    -m <output>

Evaluation:

python metrics.py \
    -m <output>
```

But the Skill should not stop at the README.

It should inspect:

```text
train.py
arguments/__init__.py
scene/dataset_readers.py
render.py
metrics.py
```

---

# Phase 2 — Verify Training Behavior

Suppose source inspection shows that `train.py` saves Gaussian checkpoints at:

```text
<output>/point_cloud/iteration_<N>/point_cloud.ply
```

and the default final iteration is:

```text
30000
```

The relevant training flow is therefore:

```text
Dataset Loader
      ↓
Scene
      ↓
Gaussian Model
      ↓
Training Loop
      ↓
point_cloud/iteration_<N>/point_cloud.ply
```

The assistant now knows that merely finding:

```text
iteration_12000
```

is not enough to call training complete.

---

# Phase 3 — Verify Dataset Behavior

Suppose `scene/dataset_readers.py` confirms that the DyNeRF loader expects:

```text
<scene>/
├── images/
├── poses_bounds.npy
└── sparse/
```

and that the six target scenes are expected to be processed separately.

Now the assistant has enough evidence to inspect the server correctly.

---

# Phase 4 — First Safe Server Audit

The first command should be read-only.

```bash
cd /data/6001_project/DynamicGaussian

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
git branch --show-current 2>/dev/null
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
    | grep -E '[p]ython|[t]rain.py|[r]ender.py|[m]etrics.py'

echo
echo "================================================================"
echo "6. IMPORTANT REPOSITORY FILES"
echo "================================================================"

find . -maxdepth 2 -type f \
    \( \
        -name "README*" \
        -o -name "train*.py" \
        -o -name "render*.py" \
        -o -name "metrics*.py" \
        -o -name "*.json" \
        -o -name "*.yaml" \
        -o -name "*.yml" \
    \) \
    2>/dev/null \
    | sort \
    | head -200

echo
echo "================================================================"
echo "DONE"
echo "================================================================"
```

---

# Example Output

Suppose the user returns:

```text
================================================================
1. CURRENT DIRECTORY
================================================================

/data/6001_project/DynamicGaussian

================================================================
2. CONDA ENVIRONMENTS
================================================================

base
dynamicgs        /opt/conda/envs/dynamicgs
rd4dgs           /opt/conda/envs/rd4dgs
spacetimegs      /opt/conda/envs/spacetimegs

================================================================
3. REPOSITORY STATUS
================================================================

 M configs/dynerf/flame_steak.json

main

91af312 update renderer

================================================================
4. GPU STATUS
================================================================

GPU 0: 43812 MiB
GPU 1: 1276 MiB
GPU 2: 836 MiB
GPU 3: 921 MiB
GPU 4: 902 MiB
GPU 5: 24102 MiB

================================================================
5. PYTHON PROCESSES
================================================================

python other_project/train.py ...
python another_project/render.py ...

================================================================
6. IMPORTANT REPOSITORY FILES
================================================================

./README.md
./train.py
./render.py
./metrics.py
./configs/dynerf/coffee_martini.json
./configs/dynerf/cook_spinach.json
./configs/dynerf/cut_roasted_beef.json
./configs/dynerf/flame_salmon_1.json
./configs/dynerf/flame_steak.json
./configs/dynerf/sear_steak.json
```

---

# Phase 5 — First Diagnosis

The Skill should conclude:

```text
Repository:
PASS

Existing Conda environment:
dynamicgs

GPU 4:
appears available

Repository modification:
configs/dynerf/flame_steak.json has local changes

Current DynamicGaussian training process:
none found
```

The assistant should **not** immediately run:

```bash
git checkout .
```

because the modified config might contain intentional experiment settings.

It should preserve the modification and inspect it later.

---

# Phase 6 — Verify Existing Environment

Activate the existing environment first.

```bash
conda activate dynamicgs

echo "================================================================"
echo "PYTHON"
echo "================================================================"

which python
python --version

echo
echo "================================================================"
echo "PYTORCH / CUDA"
echo "================================================================"

python - <<'PY'
import torch

print("torch =", torch.__version__)
print("torch cuda =", torch.version.cuda)
print("cuda available =", torch.cuda.is_available())

if torch.cuda.is_available():
    print("device count =", torch.cuda.device_count())
    print("device 0 =", torch.cuda.get_device_name(0))
PY

echo
echo "================================================================"
echo "CORE IMPORTS"
echo "================================================================"

python - <<'PY'
modules = [
    "torch",
    "numpy",
    "PIL",
]

for name in modules:
    try:
        __import__(name)
        print(f"{name}: PASS")
    except Exception as e:
        print(f"{name}: FAIL -> {e}")
PY
```

Suppose everything passes.

Then:

```text
Environment status:
PASS
```

No new Conda environment is required.

---

# Phase 7 — Dataset Audit

```bash
DATA=/dataset/dynerf

SCENES=(
    coffee_martini
    cook_spinach
    cut_roasted_beef
    flame_salmon_1
    flame_steak
    sear_steak
)

echo "================================================================"
echo "DYNERF DATASET AUDIT"
echo "================================================================"

for scene in "${SCENES[@]}"; do

    echo
    echo "------------------------------------------------------------"
    echo "SCENE: $scene"
    echo "------------------------------------------------------------"

    ROOT="$DATA/$scene"

    if [ ! -d "$ROOT" ]; then
        echo "STATUS: MISSING"
        continue
    fi

    echo "STATUS: EXISTS"

    if [ -f "$ROOT/poses_bounds.npy" ]; then
        echo "poses_bounds.npy: YES"
    else
        echo "poses_bounds.npy: NO"
    fi

    if [ -d "$ROOT/images" ]; then
        echo -n "images: "
        find "$ROOT/images" -maxdepth 1 -type f | wc -l
    else
        echo "images: MISSING"
    fi

    if [ -d "$ROOT/sparse" ]; then
        echo "sparse: YES"
    else
        echo "sparse: NO"
    fi

done
```

---

# Example Dataset Result

```text
coffee_martini
STATUS: EXISTS
poses_bounds.npy: YES
images: 5100
sparse: YES

cook_spinach
STATUS: EXISTS
poses_bounds.npy: YES
images: 5100
sparse: YES

cut_roasted_beef
STATUS: EXISTS
poses_bounds.npy: YES
images: 5100
sparse: YES

flame_salmon_1
STATUS: EXISTS
poses_bounds.npy: YES
images: 5100
sparse: YES

flame_steak
STATUS: EXISTS
poses_bounds.npy: YES
images: 5100
sparse: YES

sear_steak
STATUS: EXISTS
poses_bounds.npy: YES
images: 5100
sparse: YES
```

Therefore:

```text
Dataset:
6 / 6 PASS
```

---

# Phase 8 — Existing Experiment Audit

Now inspect outputs.

```bash
ROOT=/data/6001_project/DynamicGaussian

echo "================================================================"
echo "OUTPUT DIRECTORIES"
echo "================================================================"

find "$ROOT/output" \
    -maxdepth 2 \
    -type d \
    2>/dev/null \
    | sort

echo
echo "================================================================"
echo "CHECKPOINTS"
echo "================================================================"

find "$ROOT/output" \
    -type f \
    -name "point_cloud.ply" \
    2>/dev/null \
    | sort

echo
echo "================================================================"
echo "LOGS"
echo "================================================================"

find "$ROOT/logs" \
    -type f \
    -name "*.log" \
    2>/dev/null \
    | sort
```

---

# Example Checkpoints

Suppose the output is:

```text
output/coffee_martini/point_cloud/iteration_30000/point_cloud.ply

output/cook_spinach/point_cloud/iteration_30000/point_cloud.ply

output/cut_roasted_beef/point_cloud/iteration_7000/point_cloud.ply
output/cut_roasted_beef/point_cloud/iteration_12000/point_cloud.ply

output/flame_salmon_1/point_cloud/iteration_30000/point_cloud.ply

output/sear_steak/point_cloud/iteration_7000/point_cloud.ply
```

No output exists for:

```text
flame_steak
```

---

# Phase 9 — Training Status Diagnosis

Because the official target is:

```text
30000 iterations
```

the Skill determines:

```text
coffee_martini:
30000 / 30000
TRAIN_FINISHED

cook_spinach:
30000 / 30000
TRAIN_FINISHED

cut_roasted_beef:
12000 / 30000
TRAIN_INTERRUPTED

flame_salmon_1:
30000 / 30000
TRAIN_FINISHED

flame_steak:
0 / 30000
NOT_STARTED

sear_steak:
7000 / 30000
UNKNOWN / likely interrupted
```

But `sear_steak` should not yet be called failed until its log is checked.

---

# Phase 10 — Inspect Logs

```bash
SCENES=(
    coffee_martini
    cook_spinach
    cut_roasted_beef
    flame_salmon_1
    flame_steak
    sear_steak
)

for scene in "${SCENES[@]}"; do

    echo
    echo "================================================================"
    echo "LOG: $scene"
    echo "================================================================"

    LOG=$(find logs \
        -type f \
        -name "*${scene}*.log" \
        -printf "%T@ %p\n" \
        2>/dev/null \
        | sort -nr \
        | head -1 \
        | cut -d' ' -f2-)

    echo "LATEST=$LOG"

    if [ -n "$LOG" ]; then
        tail -40 "$LOG"
    else
        echo "NO LOG FOUND"
    fi

done
```

---

# Example Log Findings

Suppose the logs show:

```text
coffee_martini:
Training complete.
Saving Gaussians at iteration 30000.

cook_spinach:
Training complete.
Saving Gaussians at iteration 30000.

cut_roasted_beef:
CUDA out of memory
iteration 12431

flame_salmon_1:
Training complete.
Saving Gaussians at iteration 30000.

flame_steak:
NO LOG FOUND

sear_steak:
FileNotFoundError:
configs/dynerf/sear_steak.json
```

Now the state is much clearer.

---

# Phase 11 — Render Audit

```bash
echo "================================================================"
echo "RENDER DIRECTORIES"
echo "================================================================"

find output \
    -type d \
    \( \
        -name "renders" \
        -o -name "render" \
        -o -name "test" \
        -o -name "ours_*" \
    \) \
    2>/dev/null \
    | sort
```

Suppose the repository stores test renders as:

```text
output/<scene>/test/ours_30000/renders/
```

Count them:

```bash
SCENES=(
    coffee_martini
    cook_spinach
    cut_roasted_beef
    flame_salmon_1
    flame_steak
    sear_steak
)

for scene in "${SCENES[@]}"; do

    DIR="output/$scene/test/ours_30000/renders"

    echo
    echo "------------------------------------------------------------"
    echo "$scene"
    echo "------------------------------------------------------------"

    if [ -d "$DIR" ]; then
        echo -n "render count: "
        find "$DIR" -maxdepth 1 -type f -name "*.png" | wc -l
    else
        echo "render: MISSING"
    fi

done
```

---

# Example Render Result

```text
coffee_martini
render count: 300

cook_spinach
render: MISSING

cut_roasted_beef
render: MISSING

flame_salmon_1
render count: 300

flame_steak
render: MISSING

sear_steak
render: MISSING
```

---

# Phase 12 — Evaluation Audit

```bash
echo "================================================================"
echo "METRICS"
echo "================================================================"

find output \
    -type f \
    \( \
        -name "results.json" \
        -o -name "metrics.json" \
        -o -name "per_view.json" \
        -o -name "*.csv" \
    \) \
    2>/dev/null \
    | sort
```

Suppose only:

```text
output/coffee_martini/results.json
output/flame_salmon_1/results.json
```

exist.

Inspect them:

```bash
python - <<'PY'
import json
from pathlib import Path

for scene in [
    "coffee_martini",
    "flame_salmon_1",
]:
    p = Path("output") / scene / "results.json"

    print("=" * 60)
    print(scene)
    print("=" * 60)

    if not p.exists():
        print("MISSING")
        continue

    try:
        print(json.dumps(json.load(open(p)), indent=2))
    except Exception as e:
        print("ERROR:", e)
PY
```

---

# Phase 13 — Final State Table

At this point, the assistant has enough evidence to produce:

```text
scene                 train          render      eval        status
---------------------------------------------------------------------------
coffee_martini        30000/30000    YES         YES         COMPLETE
cook_spinach          30000/30000    NO          NO          TRAIN_FINISHED
cut_roasted_beef      12000/30000    NO          NO          TRAIN_INTERRUPTED
flame_salmon_1        30000/30000    YES         YES         COMPLETE
flame_steak           0/30000        NO          NO          NOT_STARTED
sear_steak            7000/30000     NO          NO          FAILED
```

---

# Phase 14 — Explain the Root Causes

The assistant should explain scene-by-scene.

## coffee_martini

```text
Training:
complete

Rendering:
complete

Evaluation:
complete

Status:
COMPLETE
```

No action required.

---

## cook_spinach

```text
Training:
complete at iteration 30000

Rendering:
missing

Evaluation:
missing

Status:
TRAIN_FINISHED
```

Required:

```text
render
↓
evaluation
```

Do not retrain.

---

## cut_roasted_beef

The latest checkpoint is:

```text
iteration_12000
```

and the log ends in:

```text
CUDA out of memory
```

Therefore:

```text
TRAIN_INTERRUPTED
```

The next step is **not** necessarily to restart training from zero.

First inspect the repository's resume implementation.

---

## flame_salmon_1

```text
Training:
complete

Rendering:
complete

Evaluation:
complete

Status:
COMPLETE
```

No action required.

---

## flame_steak

No checkpoint and no log exist.

Therefore:

```text
NOT_STARTED
```

Before training, inspect the local config modification:

```text
configs/dynerf/flame_steak.json
```

because `git status` showed that this file has changed.

Do not automatically reset it.

---

## sear_steak

The latest log shows:

```text
FileNotFoundError:
configs/dynerf/sear_steak.json
```

This is not a CUDA issue and not a reason to rebuild the environment.

The likely cause is:

```text
wrong config path
or
missing config file
```

The next action should inspect the config system.

---

# Phase 15 — Inspect Resume Support

For `cut_roasted_beef`, search the source code:

```bash
grep -RniE \
    "resume|checkpoint|start_checkpoint|restore|load.*checkpoint" \
    . \
    --include="*.py" \
    --include="*.sh" \
    2>/dev/null \
    | head -100
```

Suppose `train.py` contains:

```python
parser.add_argument("--start_checkpoint", type=str, default=None)
```

and later:

```python
if checkpoint:
    model_params, first_iter = torch.load(checkpoint)
    gaussians.restore(model_params, opt)
```

Now resume support is confirmed.

The assistant can safely recommend resume rather than restart.

---

# Phase 16 — Minimum Safe Next Actions

Do not rerun everything.

The remaining work is:

```text
cook_spinach:
render → evaluation

cut_roasted_beef:
resume training → render → evaluation

flame_steak:
inspect modified config → train → render → evaluation

sear_steak:
fix config path issue → resume or retrain depending on checkpoint validity
```

---

# Phase 17 — Example Safe Batch Script

Only after diagnosis should the assistant provide execution commands.

The exact arguments must come from the repository.

For this fictional example:

```bash
cd /data/6001_project/DynamicGaussian

conda activate dynamicgs

export CUDA_VISIBLE_DEVICES=4

mkdir -p logs

echo "================================================================"
echo "SAFE CONTINUATION BATCH"
echo "================================================================"


# ============================================================
# 1. cook_spinach
# Training already complete.
# Only render + evaluation.
# ============================================================

SCENE=cook_spinach
OUT="output/$SCENE"

echo
echo "############################################################"
echo "SCENE: $SCENE"
echo "STAGE: RENDER"
echo "############################################################"

python render.py \
    -m "$OUT" \
    2>&1 | tee "logs/${SCENE}_render.log"

status=${PIPESTATUS[0]}

if [ "$status" -ne 0 ]; then

    echo "FAILED: $SCENE / RENDER"

else

    echo "RENDER SUCCESS: $SCENE"

    python metrics.py \
        -m "$OUT" \
        2>&1 | tee "logs/${SCENE}_eval.log"

    status=${PIPESTATUS[0]}

    if [ "$status" -ne 0 ]; then
        echo "FAILED: $SCENE / EVAL"
    else
        echo "COMPLETE: $SCENE"
    fi

fi


# ============================================================
# 2. cut_roasted_beef
# Resume existing training.
# ============================================================

SCENE=cut_roasted_beef
OUT="output/$SCENE"
CKPT="$OUT/chkpnt12000.pth"

echo
echo "############################################################"
echo "SCENE: $SCENE"
echo "STAGE: RESUME TRAIN"
echo "############################################################"

if [ ! -f "$CKPT" ]; then

    echo "FAILED: $SCENE"
    echo "REASON: expected checkpoint missing:"
    echo "$CKPT"

else

    python train.py \
        -s "/dataset/dynerf/$SCENE" \
        -m "$OUT" \
        --start_checkpoint "$CKPT" \
        2>&1 | tee "logs/${SCENE}_resume.log"

    status=${PIPESTATUS[0]}

    if [ "$status" -ne 0 ]; then

        echo "FAILED: $SCENE / TRAIN"

    else

        echo "TRAIN SUCCESS: $SCENE"

        python render.py \
            -m "$OUT" \
            2>&1 | tee "logs/${SCENE}_render.log"

        status=${PIPESTATUS[0]}

        if [ "$status" -ne 0 ]; then

            echo "FAILED: $SCENE / RENDER"

        else

            python metrics.py \
                -m "$OUT" \
                2>&1 | tee "logs/${SCENE}_eval.log"

            status=${PIPESTATUS[0]}

            if [ "$status" -ne 0 ]; then
                echo "FAILED: $SCENE / EVAL"
            else
                echo "COMPLETE: $SCENE"
            fi

        fi

    fi

fi


# ============================================================
# 3. flame_steak
#
# Do NOT run automatically here until the modified config
# has been inspected.
# ============================================================

echo
echo "############################################################"
echo "SCENE: flame_steak"
echo "STATUS: HOLD"
echo "REASON: modified config requires inspection"
echo "############################################################"


# ============================================================
# 4. sear_steak
#
# Do NOT retry until the config path issue has been diagnosed.
# ============================================================

echo
echo "############################################################"
echo "SCENE: sear_steak"
echo "STATUS: HOLD"
echo "REASON: previous FileNotFoundError requires config diagnosis"
echo "############################################################"


echo
echo "================================================================"
echo "SAFE CONTINUATION BATCH FINISHED"
echo "================================================================"
```

---

# Why This Is Better Than Restarting Everything

A naive approach might run:

```bash
for scene in "${SCENES[@]}"; do
    python train.py ...
done
```

That would unnecessarily retrain:

```text
coffee_martini
cook_spinach
flame_salmon_1
```

and might also repeat a known config error for:

```text
sear_steak
```

The safety-first approach instead preserves valid work and only executes missing stages.

---

# Phase 18 — Final Verification

After remaining stages finish, perform another read-only audit.

```bash
SCENES=(
    coffee_martini
    cook_spinach
    cut_roasted_beef
    flame_salmon_1
    flame_steak
    sear_steak
)

echo "================================================================"
echo "FINAL REPRODUCTION CHECK"
echo "================================================================"

for scene in "${SCENES[@]}"; do

    OUT="output/$scene"

    echo
    echo "------------------------------------------------------------"
    echo "SCENE: $scene"
    echo "------------------------------------------------------------"

    if [ -f "$OUT/point_cloud/iteration_30000/point_cloud.ply" ]; then
        echo "TRAIN: YES"
    else
        echo "TRAIN: NO"
    fi

    RENDER_DIR="$OUT/test/ours_30000/renders"

    if [ -d "$RENDER_DIR" ]; then
        echo -n "RENDER FRAMES: "
        find "$RENDER_DIR" \
            -maxdepth 1 \
            -type f \
            -name "*.png" \
            | wc -l
    else
        echo "RENDER: NO"
    fi

    if [ -f "$OUT/results.json" ]; then
        echo "EVAL: YES"
    else
        echo "EVAL: NO"
    fi

done
```

---

# Expected Final State

Only when all required stages are verified should the Skill report:

```text
scene                 train          render      eval      status
-------------------------------------------------------------------------
coffee_martini        30000/30000    YES         YES       COMPLETE
cook_spinach          30000/30000    YES         YES       COMPLETE
cut_roasted_beef      30000/30000    YES         YES       COMPLETE
flame_salmon_1        30000/30000    YES         YES       COMPLETE
flame_steak           30000/30000    YES         YES       COMPLETE
sear_steak            30000/30000    YES         YES       COMPLETE
```

and finally:

```text
================================================================
REPRODUCTION COMPLETE
================================================================

6 / 6 scenes completed.

Training:
6 / 6

Rendering:
6 / 6

Evaluation:
6 / 6
```

---

# Lessons from This Example

This workflow demonstrates several important rules.

## 1. Existing checkpoints are evidence

Do not erase them.

---

## 2. Training completion is not reproduction completion

Always check:

```text
train
↓
render
↓
evaluation
```

---

## 3. Existing environments should be reused when valid

Do not create another Conda environment automatically.

---

## 4. Different failures require different diagnoses

```text
CUDA OOM
```

and:

```text
FileNotFoundError
```

should not receive the same fix.

---

## 5. Local source/config changes must be preserved

A modified config may be intentional.

Do not automatically run:

```bash
git reset --hard
```

---

## 6. Resume is preferable to restarting when supported

If the repository can resume safely:

```text
12000 / 30000
```

should normally continue from the checkpoint rather than restart at iteration 0.

---

## 7. A batch should isolate failures

One failed scene should not prevent unrelated scenes from finishing.

---

# Core Takeaway

A reliable reproduction assistant should not ask:

> “What command should I run?”

first.

It should ask:

> “What has already happened, and what evidence proves it?”

Then:

```text
Inspect
↓
Understand
↓
Diagnose
↓
Continue only what is missing
↓
Verify
```

That is the purpose of `paper-reproduction-safety-check`.

> **Never restart a reproduction experiment before understanding its current state.**
