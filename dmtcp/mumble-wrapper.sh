#!/bin/bash
# Author: Dolphin Whisperer
# Email: jeremy.bell@nih.gov
# Created: 2025-04-20
# Description: This script submits 10,000 tasks in chunks of 2000 each, 10 running at once
#
TOTAL=10000
MAXARRAY=2000
CONCURRENCY=4
SCRIPT=dmtcp-array.sbatch   # your script

for (( offset=0; offset<TOTAL; offset+=MAXARRAY )); do
  # compute how many tasks in this chunk
  remain=$(( TOTAL - offset ))
  if (( remain > MAXARRAY )); then
    n=$MAXARRAY
  else
    n=$remain
  fi

  # sbatch an array 1–n, export OFFSET
  sbatch \
    --array=1-${n}%${CONCURRENCY} \
    --export=ALL,OFFSET=${offset} \
    ${SCRIPT}
done
