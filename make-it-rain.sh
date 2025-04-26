#!/bin/bash
# Author: Dolphin Whisperer
# Created: 2025-04-23
# Description: This shell script submits a SLURM batch script (pirple-rain.sbatch) launches a large-scale array job (2000 tasks)
# where each task performs iterative work with checkpointing and automatic resubmission.

# launch the full job array (1999 jobs)
date
sbatch purple-rain.sbatch
date
