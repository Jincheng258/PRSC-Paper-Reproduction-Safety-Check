# Paper Reproduction Safety Check

> A reusable safety-first workflow for auditing and continuing research code reproductions without blindly reinstalling environments, modifying code, or restarting experiments.

`paper-reproduction-safety-check` is a reusable AI Skill designed for reproducing research codebases, especially projects involving:

* 3D Gaussian Splatting
* 4D / Dynamic Gaussian Splatting
* NeRF
* Computer Vision
* Computer Graphics
* Robotics
* Deep Learning research repositories

Its core principle is simple:

> **Inspect first. Understand second. Execute last.**

---

## Why?

When reproducing a research paper, the server is rarely in a clean state.

You may already have:

* Conda environments
* downloaded datasets
* partially completed training
* checkpoints
* rendered results
* evaluation metrics
* modified configurations
* running GPU jobs
* failed experiments and useful logs

A naive assistant may immediately suggest:

```bash
conda create ...
pip install ...
python train.py ...
```

This can cause:

* duplicated environments
* broken dependencies
* overwritten experiments
* unnecessary retraining
* GPU conflicts
* incorrect dataset configurations
* lost debugging evidence

This Skill therefore **audits the current state before taking action**.

---

# What It Does

The Skill checks the reproduction pipeline in the following order:

```text
README
   ↓
Relevant Source Code
   ↓
Conda Environment
   ↓
Dataset
   ↓
GPU / Running Processes
   ↓
Logs
   ↓
Checkpoints
   ↓
Rendering
   ↓
Evaluation
   ↓
Current Reproduction State
   ↓
Minimum Safe Next Action
```

---

# Key Features

## Source-code-aware

The README is not treated as the only source of truth.

The Skill also inspects relevant implementation files such as:

```text
train.py
render.py
eval.py
arguments/
configs/
scene/
dataset loaders
checkpoint logic
```

This helps detect situations where documentation and actual implementation differ.

---

## Environment reuse first

The first environment check is normally:

```bash
conda env list
```

The Skill prefers:

```text
Reuse existing environment
```

over:

```text
Create another environment
```

unless there is clear evidence that the existing environment is incompatible.

---

## Reproduction-state auditing

Instead of simply answering:

```text
"The experiment looks finished."
```

the Skill attempts to determine an explicit state:

| State               | Meaning                            |
| ------------------- | ---------------------------------- |
| `NOT_STARTED`       | Training has not started           |
| `ENV_ERROR`         | Environment problem                |
| `DATA_ERROR`        | Dataset problem                    |
| `TRAINING`          | Training is currently running      |
| `TRAIN_INTERRUPTED` | Training stopped before completion |
| `TRAIN_FINISHED`    | Training finished                  |
| `RENDER_FINISHED`   | Rendering finished                 |
| `EVAL_FINISHED`     | Evaluation finished                |
| `COMPLETE`          | Full target pipeline completed     |
| `UNKNOWN`           | Insufficient evidence              |

---

## Checkpoint-aware

A checkpoint existing does not necessarily mean training has completed.

For example:

```text
iteration_12000
```

does not mean the experiment is complete if the official target is:

```text
iteration_30000
```

The Skill verifies the expected training target before deciding the state.

---

## Render and evaluation verification

Training completion is not automatically considered a complete reproduction.

The Skill continues checking:

```text
Training
   ↓
Rendering
   ↓
Evaluation
```

including metrics such as:

```text
PSNR
SSIM
LPIPS
FPS
Storage
Training Time
```

depending on the repository.

---

# Safe Batch Execution

Research experiments often involve multiple scenes.

A single failed scene should normally **not terminate the entire batch**.

Avoid:

```bash
set -e
```

and avoid unconditional:

```bash
exit
```

inside multi-scene experiment scripts.

A safer pattern is:

```bash
SCENES=(
    coffee_martini
    cook_spinach
    cut_roasted_beef
    flame_salmon_1
    flame_steak
    sear_steak
)

mkdir -p logs

for scene in "${SCENES[@]}"; do

    echo
    echo "============================================================"
    echo "START: $scene"
    echo "============================================================"

    python train.py \
        -s "/dataset/dynerf/$scene" \
        -m "output/$scene" \
        2>&1 | tee "logs/${scene}.log"

    status=${PIPESTATUS[0]}

    if [ "$status" -ne 0 ]; then
        echo "FAILED: $scene"
        echo "EXIT CODE: $status"
        continue
    fi

    echo "SUCCESS: $scene"

done

echo "============================================================"
echo "BATCH FINISHED"
echo "============================================================"
```

This makes long-running jobs more suitable for `tmux`.

---

# Example

A realistic request might be:

```text
I am reproducing this repository:

https://github.com/example-lab/DynamicGaussian

Repository:
/data/6001_project/DynamicGaussian

Dataset:
/dataset/dynerf

Preferred GPU:
GPU 4

I worked on this experiment before but no longer remember
which scenes are finished.

First inspect the README and relevant source code.

Then determine the current status of:
- Conda environment
- dataset
- GPU
- running processes
- logs
- checkpoints
- rendering
- evaluation

Do not reinstall the environment, modify source code, or restart
training before checking the existing state.

If experiments still need to run, provide a tmux-friendly batch
script where one failed scene does not terminate the remaining jobs.
```

The expected behavior is:

```text
Inspect
   ↓
Collect evidence
   ↓
Determine current state
   ↓
Explain missing stages
   ↓
Provide minimum safe next action
```

rather than immediately launching training.

A full end-to-end example can be placed in:

```text
examples/3dgs-reproduction-check.md
```

---

# Recommended Prompt

You can use the following template:

```text
Use the paper-reproduction-safety-check workflow for this repository.

Goal:
<target reproduction>

Repository:
<repository URL>

Server path:
<repository path>

Dataset:
<dataset path>

Preferred GPU:
<GPU index>

Requirements:

1. Read the README and relevant source code first.
2. Determine how far the current reproduction has progressed.
3. Run `conda env list` and prefer existing environments.
4. Check dataset, dependencies, GPU, processes, logs,
   checkpoints, rendering, and evaluation.
5. Do not blindly reinstall dependencies.
6. Do not blindly modify source code.
7. Do not blindly restart full training.
8. Explain the official pipeline and relevant code path.
9. Identify missing stages and risks.
10. Give the minimum safe next operation.
11. For batch Bash scripts:
    - make them tmux-friendly
    - save logs
    - do not use `set -e`
    - do not terminate the batch because one scene failed
    - print clear SUCCESS / FAILED status
12. If something is uncertain, inspect evidence instead of guessing.
```

---

# Recommended Repository Structure

```text
paper-reproduction-safety-check/
│
├── README.md
├── SKILL.md
├── LICENSE
├── .gitignore
│
└── examples/
    ├── 3dgs-reproduction-check.md
    └── batch-safe-run.sh
```

---

# What This Skill Avoids

```text
✗ Blind pip install
✗ Blind conda create
✗ Blind git pull
✗ Blind code patching
✗ Blind retraining
✗ Deleting previous results
✗ Occupying arbitrary GPUs
✗ Assuming README is always correct
✗ Treating any checkpoint as completed training
✗ Treating training completion as full reproduction
```

---

# Intended Role

The Skill is designed to make an AI assistant behave less like a:

```text
Command Generator
```

and more like a:

```text
Repository Inspector
        +
Experiment Auditor
        +
Debugging Assistant
        +
Reproduction Planner
```

---

# Reproduction Checklist

Before running experiments:

```text
[ ] README inspected
[ ] relevant source code inspected
[ ] Conda environments inspected
[ ] existing environment evaluated
[ ] dataset checked
[ ] GPU checked
[ ] running processes checked
[ ] logs checked
[ ] checkpoints checked
```

Before declaring success:

```text
[ ] target training iteration reached
[ ] checkpoint verified
[ ] rendering completed
[ ] render output verified
[ ] evaluation completed
[ ] metrics saved
[ ] logs checked for hidden errors
```

Only then:

```text
REPRODUCTION COMPLETE
```

---

# License

MIT License is recommended for this project.

---

# Philosophy

> **Never restart a reproduction experiment before understanding its current state.**

**Inspect first. Understand second. Execute last.**

