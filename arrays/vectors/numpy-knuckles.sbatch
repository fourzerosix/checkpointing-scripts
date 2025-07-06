#!/bin/bash
# Author: Dolphin Whisperer
# Email: jeremy.bell@nih.gov
# Created: 2025-04-21
# Description: This script submits numpy-vectors.py to SLURM

#SBATCH --partition=all         # partition to "all"
#SBATCH -J numpy-knuckles       # set job name
#SBATCH --time=00:02:00         # set job time limit to 2 minutes
#SBATCH --nodes=1               # set node number to 1
#SBATCH --ntasks=1              #set tasks number to 1 (cpus)
#SBATCH --output=%A-%a.out      #set output filename with main job ID and task array ID
#SBATCH --error=%A-%a.err       #set error filename with main job ID and task array ID
#SBATCH --array=1-10%1          #execute 10 array jobs, 1 at a time.

# scrub a dub dub
ml purge

# load miniconda3 and the numpy conda environment ( build with the command: conda env create -f /data/user-utils/conda-envs/numpy_2.2.3.yaml )
ml miniconda3
source activate numpy_2.2.3

# run the python code, save all output to a log file corresponding the the current job task that is running
python -u numpy-vectors.py &> log.$SLURM_ARRAY_TASK_ID
