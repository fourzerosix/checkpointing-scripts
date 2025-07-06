#!/bin/bash
#SBATCH --job-name=purple-rain-requeue
#SBATCH --output=logs/purple-rain-requeue_%A_%a.out
#SBATCH --array=0-1999
#SBATCH --time=1-00:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --requeue                    # <— tell SLURM this job is requeueable

# default to 0 if not running in an array job (manual testing)
if [[ -z "$SLURM_ARRAY_TASK_ID" ]]; then
  echo "No SLURM_ARRAY_TASK_ID found; defaulting to 0"
  SLURM_ARRAY_TASK_ID=0
fi

# checkpoint file for this task
CKPT_DIR=checkpoints
CKPT_FILE=$CKPT_DIR/task_${SLURM_ARRAY_TASK_ID}.ckpt
mkdir -p logs "$CKPT_DIR"

# load or initialize step
if [[ -f "$CKPT_FILE" ]]; then
  STEP=$(<"$CKPT_FILE")
else
  STEP=0
fi

MAX_STEPS=1000000
echo "[$(date)] Task $SLURM_ARRAY_TASK_ID (Job $SLURM_JOB_ID): starting at step $STEP/$MAX_STEPS"

# ----- MAIN WORK -----
# replace `sleep 300` with your real computation
sleep 300

# checkpoint progress
(( STEP++ ))
echo "$STEP" > "$CKPT_FILE"

# ----- REQUEUE DECISION -----
if (( STEP < MAX_STEPS )); then
  echo "[$(date)] Task $SLURM_ARRAY_TASK_ID: checkpointed step $STEP — requeueing job"
  scontrol requeue "$SLURM_JOB_ID"
else
  echo "[$(date)] Task $SLURM_ARRAY_TASK_ID: completed all $MAX_STEPS steps"
fi
