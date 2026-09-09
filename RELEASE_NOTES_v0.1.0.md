# PRSC v0.1.0 — Initial Public Release

PRSC (Paper Reproduction Safety Check) is a reusable safety-first Agent Skill for auditing and continuing research-code reproductions without blindly reinstalling environments, modifying source code, deleting evidence, or restarting experiments.

## Highlights

- Inspect README and relevant source code before execution.
- Reuse existing Conda environments whenever compatible.
- Audit datasets, preprocessing, GPUs, processes, logs, checkpoints, rendering, and evaluation.
- Classify per-scene experiment state using evidence-based statuses.
- Prefer valid resume workflows over restarting from zero.
- Treat training, rendering, and evaluation as separate completion stages.
- Diagnose likely root causes before modifying source code.
- Provide tmux-friendly batch scripts where one failed scene does not terminate unrelated scenes.

## Included package

```text
paper-reproduction-safety-check/
├── SKILL.md
├── references/
│   ├── reproduction-audit.md
│   ├── debugging-policy.md
│   └── 3dgs-reproduction-check.md
└── scripts/
    └── batch-safe-run.sh
```

## Primary use cases

PRSC is particularly suited to research repositories involving:

- 3D Gaussian Splatting
- 4D / Dynamic Gaussian Splatting
- NeRF
- Computer Vision
- Computer Graphics
- Robotics
- Deep Learning experiment pipelines

## Core principle

> **Inspect first. Understand second. Execute last.**

## Important safety behavior

PRSC avoids, by default:

- blind `pip install`
- blind `conda create`
- blind source-code patching
- blind full retraining
- destructive cleanup of prior experiments
- assuming any checkpoint means training is complete
- assuming training completion means full reproduction
- terminating a multi-scene batch because one scene failed

## License

MIT License.
