#!/bin/bash
# Author: Dolphin Whisperer
# Email: jeremy.bell@nih.gov
# Created: 2025-04-20
# Description: This script:
# Loads the dmtcp module, 
# Starts a DMTCP coordinator process (small background service) listening on TCP port 7779, 
# Runs the example.cpp code on example_array, and
# Monitors the program, saving periodic checkpoint images of the process and exits cleanly when finished.

#SBATCH --partition=all
#SBATCH -J give-me-arrays
#SBATCH --output=dmtcp_array_%A_%a.out
#SBATCH --error=dmtcp_array_%A_%a.err
#SBATCH --nodes=1
#SBATCH --ntasks=10
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH --array=1-1000%10  # Run 1000 jobs, 10 at a time

# Load the DMTCP module
module load dmtcp

echo "This is job $SLURM_ARRAY_TASK_ID"

# Optional: Each array task could run in its own directory
# jobDir=Job_$SLURM_ARRAY_TASK_ID
# mkdir $jobDir
# cd $jobDir

RESTARTSCRIPT="dmtcp_restart_script.sh"
export DMTCP_QUIET=2

runcmd="./example_array"
tint=30

# Start the DMTCP coordinator on default port 7779
echo "Start coordinator"
date
dmtcp_coordinator --daemon --coord-logfile dmtcp_log.txt --exit-after-ckpt --exit-on-last -i "$tint" -p 7779

sleep 2  # Give coordinator time to start

echo "Using coordinator at localhost:7779"
hostname

if [ -f "$RESTARTSCRIPT" ]; then
    echo "Resume the application"
    CMD="dmtcp_restart -p 7779 -i $tint ckpt*.dmtcp"
    echo $CMD
    eval $CMD
else
    echo "Start the application"
    CMD="dmtcp_launch --rm --no-gzip -h localhost -p 7779 $runcmd"
    echo $CMD
    eval $CMD
fi

echo "Stopped program execution"
date
