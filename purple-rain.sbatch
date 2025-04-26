#!/bin/bash
# Author: Dolphin Whisperer
# Created: 2025-04-23
# Description: This SLURM batch script runs a large-scale array job (2000 tasks)
# where each task performs iterative work with checkpointing and automatic resubmission.
#
# In short, it does the following:
#    Defines job parameters:
#        - Array job with indices 0-1999.
#        - Each task has 1 CPU, 2GB memory, and up to 1 day of runtime.
#        - Output logs are written to logs/purple-rain-checkpoint_<jobID>_<arrayID>.out.
#    Sets up a checkpoint system:
#        - Creates a .ckpt file per task to track how many steps it has completed.
#        - If the .ckpt file exists, it resumes from the saved step.
#        - Otherwise, it starts at step 0.
#    Simulates work:
#        - Sleeps for 5 minutes to mimic a time-consuming computation.
#    Updates the checkpoint:
#        - Increments the step and saves it.
#    Handles continuation:
#        - If the task hasn’t reached MAX_STEPS (1,000,000), it automatically resubmits itself using sbatch.
#        - Otherwise, it prints a message saying it’s done.
# 
# This design is useful for long-running or restartable jobs that may exceed SLURM time limits or need fault tolerance.
#

#SBATCH --job-name=purple-rain
#SBATCH --output=logs/purple-rain-checkpoint_%A_%a.out
#SBATCH --array=0-1999
#SBATCH --time=1-00:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G

# default to 0 if not running in an array job (manual testing)
if [[ -z "$SLURM_ARRAY_TASK_ID" ]]; then
    echo "No SLURM_ARRAY_TASK_ID found; defaulting to 0"
    SLURM_ARRAY_TASK_ID=0
fi

# create directories for output and checkpointing
mkdir -p logs checkpoints

# file to track this task's progress
CKPT_FILE="checkpoints/task_${SLURM_ARRAY_TASK_ID}.ckpt"

# load any/all relevant modules (dmtcp and miniconda3 used for examples)
#ml dmtcp
#ml miniconda3

#####################
# CHECKPOINT LOGIC  #
#####################

# load or initialize step
if [[ -f "$CKPT_FILE" ]]; then
    STEP=$(cat "$CKPT_FILE")
else
    STEP=0
fi

MAX_STEPS=1000000

echo "[$(date)] Task ${SLURM_ARRAY_TASK_ID}: Starting at step $STEP of $MAX_STEPS"

# ----- MAIN -----

# simulate real work here - this sleeps for 5 minutes
sleep 300  # replace with your computation

# save progress
((STEP++))
echo "$STEP" > "$CKPT_FILE"

# ----- RE-SUBMISSION/REQUEUE -----

if [[ "$STEP" -lt "$MAX_STEPS" ]]; then
    echo "[$(date)] Task ${SLURM_ARRAY_TASK_ID}: Resubmitting to continue from step $STEP"
    sbatch --export=SLURM_ARRAY_TASK_ID=$SLURM_ARRAY_TASK_ID $0
else
    echo "[$(date)] Task ${SLURM_ARRAY_TASK_ID}: All $MAX_STEPS steps completed"
fi
