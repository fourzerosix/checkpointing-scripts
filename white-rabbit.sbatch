#!/bin/bash
# Author: Dolphin Whisperer
# Created: 2025-04-20
# Description: This script prints the time/date every minute for 33 days.
# It uses checkpointing logic to requeue the job every 6 days to avoid the 7-day wall-time limit.

#SBATCH --job-name=white-rabbit          # job name
#SBATCH --output=white-rabbit_%j.log     # output log file
#SBATCH --time=6-00:00:00                # 6-day requeue to avoid hitting 7-day wall time limit (can be adjusted)
#SBATCH --ntasks=1                       # single task
#SBATCH --cpus-per-task=1                # one CPU core per task
#SBATCH --mem=1GB                        # memory allocation
#SBATCH --requeue                        # requeue the job if it fails

# check if we are in the first, second, or third checkpoint period
START_TIME=$(date +%s)
CHECKPOINT_INTERVAL=$((6 * 24 * 60 * 60)) # 6 days in seconds
JOB_RUN_TIME=$((33 * 24 * 60 * 60))      # 33 days in seconds

# function to print the current date/time every minute
print_time() {
  while (( $(date +%s) - $START_TIME < $JOB_RUN_TIME )); do
    echo "Current date/time: $(date)"
    sleep 60
  done
}

# if we're starting fresh, print the time and set up the first checkpoint
if [ -z "$SLURM_ARRAY_TASK_ID" ]; then
  print_time
  # checkpoint logic: Submit new job after 6 days
  if (( $(date +%s) - $START_TIME >= $CHECKPOINT_INTERVAL )); then
    sbatch --time=6-00:00:00 --requeue
  fi
else
  # resubmit after 6 days
  if (( $(date +%s) - $START_TIME >= $CHECKPOINT_INTERVAL )); then
    sbatch --time=6-00:00:00 --requeue
  fi
fi
