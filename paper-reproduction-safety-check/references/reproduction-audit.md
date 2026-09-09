# Reproduction Audit Reference

Use this reference when the main `SKILL.md` needs a more detailed audit checklist.

## Repository

Inspect:

```bash
pwd
git status --short
git branch --show-current
git log -1 --oneline
```

Do not automatically clean, reset, or pull.

## Environment

Start with:

```bash
conda env list
```

Then verify the candidate environment:

```bash
which python
python --version
python - <<'PY'
import torch
print(torch.__version__)
print(torch.version.cuda)
print(torch.cuda.is_available())
PY
```

Test repository-specific imports before installing or upgrading packages.

## Dataset

Verify directory structure against the actual dataset loader. Common checks include:

```bash
find /dataset/path/scene -maxdepth 2 -type d | sort
find /dataset/path/scene -maxdepth 2 -type f | head -100
```

Count images/views when meaningful:

```bash
find /dataset/path/scene/images -maxdepth 1 -type f | wc -l
```

## Preprocessing

Look for repository-specific artifacts such as:

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

Do not rerun preprocessing until existing outputs have been checked.

## GPU and processes

```bash
nvidia-smi
ps -eo pid,etime,%cpu,%mem,cmd
```

For one GPU:

```bash
nvidia-smi -i <GPU_ID> \
  --query-gpu=index,name,memory.used,memory.total,utilization.gpu,power.draw \
  --format=csv
```

## Experiment directories

Common locations include:

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

Use scene names, configs, timestamps, and log contents together to identify the intended run.

## Logs

Locate logs:

```bash
find . -type f \
  \( -name "*.log" -o -name "*.out" -o -name "*.txt" \) \
  2>/dev/null | sort
```

Search likely fatal errors:

```bash
grep -RniE \
  "Traceback|Error|Exception|CUDA out of memory|Killed|Segmentation fault|FAILED" \
  logs 2>/dev/null
```

Do not rely only on the final line. Training may have saved a valid checkpoint before a later render or evaluation failure.

## Checkpoints

Search likely checkpoint formats:

```bash
find . -type f \
  \( -name "*.pth" -o -name "*.pt" -o -name "*.ckpt" -o -name "point_cloud.ply" \) \
  2>/dev/null | sort
```

Always compare the latest checkpoint with the repository's target iteration/epoch.

## Resume

Search implementation rather than inventing arguments:

```bash
grep -RniE \
  "resume|checkpoint|start_checkpoint|restore|load.*checkpoint" \
  . \
  --include="*.py" \
  --include="*.sh" \
  --include="*.yaml" \
  --include="*.yml" \
  --include="*.json" \
  2>/dev/null | head -100
```

## Render

Look for repository-specific render outputs:

```text
render/
renders/
test/
train/
ours_*/
video/
```

Count outputs and compare against expected frames/views.

## Evaluation

Search official metrics and result files:

```bash
grep -RniE "PSNR|SSIM|LPIPS|FPS" output logs results 2>/dev/null
```

Look for:

```text
results.json
metrics.json
per_view.json
metrics.txt
results.txt
*.csv
```

## Suggested state table

```text
scene                 env   data   train        render   eval   status
--------------------------------------------------------------------------
coffee_martini        OK    OK     30000/30000  YES      YES    COMPLETE
cook_spinach          OK    OK     30000/30000  NO       NO     TRAIN_FINISHED
cut_roasted_beef      OK    OK     12000/30000  NO       NO     TRAIN_INTERRUPTED
```

## Final audit checklist

Before execution:

```text
[ ] README inspected
[ ] relevant source code inspected
[ ] repository state inspected
[ ] Conda environments inspected
[ ] candidate environment validated
[ ] dataset structure validated
[ ] preprocessing checked
[ ] requested GPU checked
[ ] matching processes checked
[ ] old outputs/logs checked
[ ] checkpoints checked
[ ] resume logic checked if needed
```

Before declaring full quantitative reproduction complete:

```text
[ ] target training iteration reached
[ ] checkpoint verified
[ ] rendering completed
[ ] output frame/view count checked
[ ] official evaluation completed
[ ] metrics saved
[ ] no unresolved fatal errors
```
