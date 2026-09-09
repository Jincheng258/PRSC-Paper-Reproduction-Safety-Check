#!/usr/bin/env bash

# Paper Reproduction Safety Check
# Safe multi-scene batch execution example.
#
# Design goals:
# - tmux friendly
# - preserve logs
# - no `set -e`
# - no batch-level `exit`
# - one failed scene does not stop later scenes

GPU_ID=4
DATA_ROOT="/dataset/dynerf"
OUTPUT_ROOT="./output"
LOG_ROOT="./logs"

SCENES=(
    coffee_martini
    cook_spinach
    cut_roasted_beef
    flame_salmon_1
    flame_steak
    sear_steak
)

mkdir -p "$OUTPUT_ROOT" "$LOG_ROOT"

echo "============================================================"
echo "PAPER REPRODUCTION BATCH"
echo "============================================================"
echo "GPU:        $GPU_ID"
echo "DATA:       $DATA_ROOT"
echo "OUTPUT:     $OUTPUT_ROOT"
echo "LOGS:       $LOG_ROOT"
echo "============================================================"

for scene in "${SCENES[@]}"; do
    echo
    echo "############################################################"
    echo "START: $scene"
    echo "############################################################"

    SCENE_DATA="$DATA_ROOT/$scene"
    SCENE_OUTPUT="$OUTPUT_ROOT/$scene"
    SCENE_LOG="$LOG_ROOT/${scene}.log"

    if [ ! -d "$SCENE_DATA" ]; then
        echo "FAILED: $scene"
        echo "REASON: dataset directory does not exist:"
        echo "$SCENE_DATA"
        continue
    fi

    if [ -d "$SCENE_OUTPUT" ]; then
        echo "NOTICE: existing output found:"
        echo "$SCENE_OUTPUT"
        echo "The script will not delete it automatically."
    fi

    # Replace the example arguments below with the repository's
    # actual training arguments after inspecting its source code.
    CUDA_VISIBLE_DEVICES="$GPU_ID" \
    python train.py \
        -s "$SCENE_DATA" \
        -m "$SCENE_OUTPUT" \
        2>&1 | tee "$SCENE_LOG"

    TRAIN_STATUS=${PIPESTATUS[0]}

    if [ "$TRAIN_STATUS" -ne 0 ]; then
        echo
        echo "============================================================"
        echo "FAILED: $scene"
        echo "STAGE: TRAIN"
        echo "EXIT CODE: $TRAIN_STATUS"
        echo "LOG: $SCENE_LOG"
        echo "============================================================"
        continue
    fi

    echo
    echo "============================================================"
    echo "TRAIN SUCCESS: $scene"
    echo "============================================================"
done

echo
echo "############################################################"
echo "BATCH FINISHED"
echo "############################################################"
