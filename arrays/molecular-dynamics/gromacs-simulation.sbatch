#!/bin/bash
# Author: Dolphin Whisperer
# Email: jeremy.bell@nih.gov
# Created: 2025-04-21
#
# Below is an example of application-level checkpointing that shows how to implement a 120-hour GROMACS job using multiple shorter jobs on the all partition.
# We Use SLURM job arrays and the GROMACS built-in checkpointing option. The script sets the checkpoint flag -cpi state preceding the filename to dump checkpoints.
# This directs mdrun to the checkpoint in state.cpt when loading the state. The SLURM option --array=1-10%1 creates 10 SLURM array tasks and runs 1 task job serially for 12 hours
# The variable %A denotes the main job ID, while %a denotes the task ID (i.e., spanning 1-10).
#
#SBATCH --partition=all
#SBATCH --nodes=2
#SBATCH --time=12:00:00
#SBATCH --job-name=true-gromance
#SBATCH --ntasks=10
#SBATCH --array=1-10%1
#SBATCH --output=checkpointing-test-%A_%a.out
#SBATCH --error=checkpointing-test-%A_%a.err
 
ml cuda/10.2.89-tg6wrnc
ml gcc/11.3.0-x5pw2ys
ml openmpi/4.1.5-nikv762
ml gromacs/2024.1-jc4rqaz
 
source /data/apps/software/spack/linux-rocky9-x86_64_v3/gcc-11.3.1/gromacs-2024.1-jc4rqazao6qak25hphszm23rin2qxuy6/bin/GMXRC.bash
 
srun --mpi=pmix -n $SLURM_NTASKS gmx_mpi mdrun -ntomp 1 -s myrun.tpr -v -dlb yes -cpi state
