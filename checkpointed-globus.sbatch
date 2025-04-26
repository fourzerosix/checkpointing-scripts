#!/bin/bash
# Author: Dolphin Whisperer
# Created: 2025-04-22
# Description: This script sets up a checkpointed Globus job that requeues indefinitely every 1 day and 23 hours

#SBATCH --job-name=CpR_GCP
#SBATCH --nodes=2
#SBATCH --ntasks=2
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=16G
#SBATCH --time=1-23:00:00                  # just under 2 days to allow time for requeueing
#SBATCH --output=globus-slurm-stdout-%J.log
#SBATCH --error=globus-slurm-stderr-%J.log
#SBATCH --mail-type=all
#SBATCH --mail-user=jeremy.bell@nih.gov
#SBATCH --requeue                          # allow the job to be requeued on failure or request
#SBATCH --signal=B:USR1@600                # send SIGUSR1 10 minutes (600s) before timeout

# load Globus Connect Personal
ml globus-personal/3.2.3-noo3lse

### optional ### - set up a persistent state directory
STATE_DIR="$HOME/globus_state"
mkdir -p "$STATE_DIR"

# trap the USR1 signal to trigger a graceful checkpoint + requeue
trap_handler() {
    echo "[$(date)] Caught SIGUSR1 signal. Preparing for requeue..."

    # save checkpoint state (if needed)
    echo "[$(date)] Saving state to $STATE_DIR..."
    # touch "$STATE_DIR/checkpoint.$SLURM_JOB_ID"   # e.g.

    # requeue the job (#SBATCH --requeue)
    echo "[$(date)] Requeuing job $SLURM_JOB_ID"
    scontrol requeue $SLURM_JOB_ID

    exit 0
}

trap 'trap_handler' SIGUSR1

# run the GCP job (replace -restrict-paths and -shared-paths
echo "[$(date)] Starting Globus Connect Personal..."
srun globusconnectpersonal -restrict-paths rw/HERE -shared-paths rw/AND/HERE -debug -start &

# wait indefinitely (or until signaled)
wait
