#!/bin/bash
# Author: Dolphin Whisperer
# Created: 2025-04-21
# Description: This script submits sensorflow-long.py to SLURM

#SBATCH --partition=gpu                 # partition to "gpu"
#SBATCH -J tensorflow-checkpointing     # job name
#SBATCH --time=01:00:00                 # set job time limit
#SBATCH --nodes=1                       # set number of nodes to 1
#SBATCH --ntasks=1                      # set number of cpus to 1
#SBATCH --gres=gpu:1                    # request 1 GPU
#SBATCH --mem=10GB                      # request 10GB of RAM memory
#SBATCH --output=cpr_tensor-%A-%a.out   # set output filename with main job ID and task array ID
#SBATCH --error=cpr_tensor-%A-%a.err    # set error filename with main job ID and task array ID
#SBATCH --array=1-100%1                 # execute 100 array jobs, 1 at a time.

# scrub a dub dub
ml purge

# load miniconda3 and the tf conda environment ( build with the command: conda env create -f /data/user-utils/conda-envs/tensorflow-gpu_2.18.0.yaml )
ml miniconda3
source activate tensorflow-gpu_2.18.0

# define the number of steps based on the job id:
numOfSteps=$(( 500 * SLURM_ARRAY_TASK_ID ))

# run the python code, save all output to a log file corresponding the the current job task that's running:
python sensorflow-long.py $numOfSteps &> log.$SLURM_ARRAY_TASK_ID
