# End-to-End Example: Dynamic Gaussian Reproduction Audit

This fictional but realistic example shows how the skill should behave when a user wants to continue a partially completed DyNeRF / dynamic Gaussian reproduction.

## User request

```text
Repository:
/data/6001_project/DynamicGaussian

Dataset:
/dataset/dynerf

Preferred GPU:
4

Scenes:
coffee_martini
cook_spinach
cut_roasted_beef
flame_salmon_1
flame_steak
sear_steak

I worked on this before but do not remember what finished.
Inspect README and relevant source code first, then check the existing
Conda environment, data, preprocessing, GPU, processes, logs,
checkpoints, renders and evaluation.

Do not reinstall, patch, delete old results, or restart everything
before checking the current state.
```

## Phase 1: establish the official pipeline

Suppose source inspection confirms:

```text
dataset loader
  -> train.py
  -> point_cloud/iteration_<N>/point_cloud.ply
  -> render.py
  -> metrics.py
```

and the final target is 30000 iterations.

This means `iteration_12000` is evidence of progress, not completion.

## Phase 2: first read-only audit

```bash
cd /data/6001_project/DynamicGaussian

pwd
conda env list
git status --short
git branch --show-current
git log -1 --oneline
nvidia-smi
ps -eo pid,etime,%cpu,%mem,cmd | grep -E '[p]ython|[t]rain|[r]ender|[m]etrics'
```

Suppose the result shows:

```text
Existing environment: dynamicgs
GPU 4: mostly free
Local modification: configs/dynerf/flame_steak.json
No matching DynamicGaussian training process
```

Do not reset the modified config; inspect it later.

## Phase 3: validate the existing environment

```bash
conda activate dynamicgs
which python
python --version

python - <<'PY'
import torch
print(torch.__version__)
print(torch.version.cuda)
print(torch.cuda.is_available())
PY
```

If the core imports and repository extensions pass, reuse the environment.

## Phase 4: validate data

Compare the dataset against the actual loader. For example:

```bash
DATA=/dataset/dynerf
SCENES=(coffee_martini cook_spinach cut_roasted_beef flame_salmon_1 flame_steak sear_steak)

for scene in "${SCENES[@]}"; do
    echo "==== $scene ===="
    test -d "$DATA/$scene" && echo "scene: YES" || echo "scene: NO"
    test -f "$DATA/$scene/poses_bounds.npy" && echo "poses: YES" || echo "poses: NO"
    test -d "$DATA/$scene/sparse" && echo "sparse: YES" || echo "sparse: NO"
    if [ -d "$DATA/$scene/images" ]; then
        find "$DATA/$scene/images" -maxdepth 1 -type f | wc -l
    fi
done
```

Suppose all six scenes pass.

## Phase 5: inspect checkpoints and logs

Suppose existing checkpoints are:

```text
coffee_martini      iteration_30000
cook_spinach        iteration_30000
cut_roasted_beef    iteration_12000
flame_salmon_1      iteration_30000
flame_steak         none
sear_steak          iteration_7000
```

Logs then show:

```text
coffee_martini: complete
cook_spinach: complete
cut_roasted_beef: CUDA OOM around iteration 12431
flame_salmon_1: complete
flame_steak: no log
sear_steak: FileNotFoundError for a config path
```

Now the state can be classified with evidence.

## Phase 6: inspect render and evaluation

Suppose only these scenes have full render/eval outputs:

```text
coffee_martini
flame_salmon_1
```

Then the final audit table is:

```text
scene                 train          render   eval   status
---------------------------------------------------------------
coffee_martini        30000/30000    YES      YES    COMPLETE
cook_spinach          30000/30000    NO       NO     TRAIN_FINISHED
cut_roasted_beef      12000/30000    NO       NO     TRAIN_INTERRUPTED
flame_salmon_1        30000/30000    YES      YES    COMPLETE
flame_steak           0/30000        NO       NO     NOT_STARTED
sear_steak            7000/30000     NO       NO     FAILED
```

## Phase 7: identify only missing work

```text
cook_spinach:
render -> evaluation

cut_roasted_beef:
inspect resume support -> resume -> render -> evaluation

flame_steak:
inspect modified config -> train -> render -> evaluation

sear_steak:
diagnose config-path failure -> decide whether resume or retry is valid
```

Do not rerun `coffee_martini` or `flame_salmon_1`.

## Phase 8: resume only after confirming support

Search the source:

```bash
grep -RniE \
  "resume|checkpoint|start_checkpoint|restore|load.*checkpoint" \
  . --include="*.py" --include="*.sh" 2>/dev/null | head -100
```

If the implementation confirms a valid `--start_checkpoint` argument, use it. Do not invent it before code inspection.

## Correct final conclusion

A good assistant response after the audit is not:

> Run all six scenes again.

It is:

> Two scenes are complete. One only needs render/evaluation. One has an interrupted training checkpoint and should be resumed if the code supports it. One has not started but has a locally modified config that should be inspected first. One failed because of a config-path error and should be diagnosed before retrying.

That is the purpose of the skill: recover the real experiment state, preserve valid work, and continue only what is missing.
