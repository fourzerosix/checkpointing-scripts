## SLURM Priority & Wall-Times
### Priority
[SLURM Priority](https://skyline.domain.foo.bar/slurm-priority/) assigns each job a **priority** score to decide what gets scheduled next. Priority is based on:
- **Fairshare** tracks past resource usage per user/project/account. Users who have used fewer resources recently get higher priority.
- **Age** tracks how long your job’s been waiting. Older jobs (waiting longer) gain priority over time.
- **Job size** tracks how many nodes/CPUs you’ve requested and/or are currently using. Larger jobs may be prioritized to make efficient use of resources.
- **Partition** tracks the varying weights of different partitions.
- **QoS** tracks and can adjust the base priority of jobs. It can control things like:
 	- Priority boost (Priority)
  - Maximum wall time
  - Maximum number of jobs per user/account
  - Preemption (ability to interrupt lower-QoS jobs)
 
*“There are two paths people can take. They can either play now and pay later or pay now and play later. Regardless of the choice, one thing is certain. [SLURM] will demand a payment.”*
  — John C. SlurmWall
 
### Wall Time
The wall time is how long your job is allowed to run — set in srun command as a flag or in an sbatch script with - `#SBATCH --time=HH:MM:SS`.
- If your job exceeds the wall time, SLURM **terminates it**, if your request exceeds the wall time limits, your job is put in “`PD`” or pending state, oftentimes with an error/reason ( e.g., `QOSMaxWallDurationPerJobLimit` )
- Setting a shorter wall time can help your job start sooner, since the scheduler can fit it into smaller time gaps in the schedule.
 
---

*There are many ways to break jobs up that allow for use under these circumstances. Normally, it’s a matter of decomposing your workflow as you interact with the cluster - and/or adjusting your submission scripts to break jobs into smaller parts. Applying fault tolerance techniques to your HPC workflows adds exponential benefit to your job submission experience.*

---
 
## Using Arrays
### Basic Arrays
Arrays are a powerful concept in both general programming and in job scheduling systems like SLURM. They offer a mechanism for interpreting, submitting, and managing collections of similar elements or workflows, offering:
- **Efficient storage**: Instead of creating multiple variables ( `job1`, `job2`, `job3`, etc. etc. ) you store them in a single variable ( `job[ ]` ).
- **Iterability**: You can easily loop through them using constructs like for or while.
- **Scalability**: Code can adapt to more data without rewriting logic for each new variable.
- **Organization**: Keeps related data grouped logically.
 
### SLURM Job Arrays
[SLURM Job arrays](https://slurm.schedmd.com/job_array.html) offer a mechanism for submitting and managing collections of similar jobs quickly and easily - [arrays on BigSky/Skyline](https://skyline.domain.foo.bar/slurm-job-arrays/) can be:
- Specified using the `--array` flag from the command line or within a submit script ( e.g., `--array=1-1000%10` - which would submit 1 job with 1000 tasks, 10 at a time.)
- The smallest index that can be specified by a user is zero and the maximum index is `MaxArraySize` minus one:
  ```bash
  [user@host ~]$ scontrol show config  | grep -i maxarray
  MaxArraySize            = 2001

  [user@host ~]$ sbatch --array=1-2001 brain-stew.sh
  sbatch: error: Batch job submission failed: Invalid job array specification
  [user@host ~]$ sbatch --array=1-2000 brain-stew.sh
  Submitted batch job 137945
  ```
  
---
 
*Checkpointing is a fault tolerance technique based on the Backward Error Recovery (BER) technique, designed to overcome “fail-stop” failures (interruptions during the execution of a job). **This makes your jobs more resilient to crashes, partition time limits, and hardware failures, as well as <mark>aids in overcoming lab group/partition time limits by replacing your single long job with multiple shorter jobs**</mark>. You can use job arrays to set each job to run in serial. If checkpointing is used, each job will write a checkpoint file and the following job will use the latest checkpoint file to continue from the last state of the calculation. There are a variety of ways to checkpoint your jobs (some applications/modules even have “checkpointing” as a built-in feature with its own flags/options), but we’ll focus on the two most common methods, using checkpointing logic within/in-tandem with your code/submission scripts and DMTCP (Distributed MultiThreaded Checkpointing).*
 
---
 
## Checkpointing
Checkpointing from within or in-tandem with your code:
We’ve modified some existing submission scripts to leverage checkpointing, provided examples of data-science/bioinformatics software (TensorFlow/Keras/NumPy) that can leverage checkpointing within their own code, as well as written some new ones as examples, some of which involve resource requests that would be potentially inhibited or prohibited by [common SLURM scheduling limitations](https://slurm.schedmd.com/job_reason_codes.html#common_reasons) when implemented without checkpointing mechanisms in place. These scripts are only meant to outline basic principles in hopes that they’ll give you a sort of skeleton to build your code around.
 
> **SLURM Checkpointing script repository: `/data/user-utils/user-scripts/checkpointing`**
 
- `purple-rain.sbatch` runs a large-scale array job (2000 tasks) where each task performs iterative work with checkpointing - this tests SLURMs `MaxArraySize` and uses resubmission logic. 

- `purple-rain-requeue.sbatch` is the same script from above, using SLURM’s built-in requeue support instead of resubmission (which involves manually calling sbatch each time). This means, at the end of your script, SLURM will put the same job back into the queue, preserving its array index. This method is more efficient because:
  - There are fewer jobs in the scheduler. You don’t flood the queue with brand-new jobs - SLURM just bumps your existing one to the back of the queue,
  - You keep the same JobID and your
  - Array context is preserved, and lastly
  - Built-in fault recovery. You can also couple this with different flavors of checkpointing or module-level preemption handling.
 
---
 
*To allow your job to be requeued on failure or request, the `#SBATCH --requeue` flag must be declared in your script - re queueing is enabled on both clusters*:
   ```bash
   [user@host ~]$ scontrol show config  | grep -i requeue
   JobRequeue              = 1
   MaxBatchRequeue         = 5
   ```

---

- `white-rabbit.sbatch` sets up time-based checkpoints at a defined interval - *purposely designed to request a longer running duration than is allowed on any partition*, as well as checkpoints/requeues every 6 days to overcome the 7-day default lab-group limit . <mark>This is intended to show how using **checkpointing and preemptive requeue logic** allows a user to request as much time as they need for their job(s)</mark>. It prints the current system date/time every 60 seconds which not only exercises the I/O path to the log file, but also verifies accuracy of SLURM’s stream of logs over extended time periods.
   - Inside each branch:
     ```
     if (( $(date +%s) - $START_TIME >= $CHECKPOINT_INTERVAL )); then
     sbatch --time=6-00:00:00 --requeue
     fi
     ```
   - Once 6 days have elapsed (i.e., hitting the wall-time limit), the script submits another copy of itself
     - With the same time limit and `--requeue` flag, as well as verifies
     - That the new job will start fresh (with a new `START_TIME`), continuing the chain, which
   - Effectively “chains” five 6-day jobs together to cover ~33 days (arbitrary number) total without ever hitting the 7-day default lab-group limit.
 
- `globus-pocus.sbatch` uses a pattern called "self-requeuing" *to create an "infinite" job despite enforced job time limits*. It keeps a Globus job running "forever" by catching a warning signal 10 minutes before the job limit, gracefully saving state, and requeuing itself, automatically, by:
  - Setting up a trap with:
    ```bash
    trap_handler() { ... }
    trap trap_handler USR1
    ```
  - This means: When `SIGUSR1` is received, it runs `trap_handler` instead of just dying.
  - `trap_handler`:
    - Prints a message: "`Caught SIGUSR1`"
      *Option*: save checkpoint state (you can add your own commands here), then
    - Most importantly, it runs:
      ```bash
      scontrol requeue $SLURM_JOB_ID
      ```
    - Which asks SLURM to immediately requeue the job (then exits cleanly).

 ---
 
> **Application-Level Checkpointing/Array script repository: `/data/user-utils/user-scripts/checkpointing/arrays`**

- `/vectors` - (contains 2 scripts that are intended to work in-tandem and should reside in the same directory)
  - `numpy-knuckles.sbatch`
    - Loads the Miniconda3 module,
    - Activates a NumPy (v2.2.3) conda environment, and
    - Submits `numpy-vectors.py`, a Python TensorFlow script that:
      - Loads a dataset and defines a simple neural network model,
      - Sets up a checkpoint system where the Python codes is managing the saving/restoring progress (less reliant on the system), then
      - Trains the model with the checkpoint callback active, that way
      - When you checkpoint and restore the model, you are effectively saving and restoring the trained arrays of neural network weights, which means
      - Next time you submit, the script detects the checkpoint, loads the saved model, and continues training.
- `/tensors` (contains 3 scripts that are intended to work in-tandem and should reside in the same directory)
  - `kerasell.sbatch`
    - Loads the Miniconda3 module,
    - Activates a TensorFlow-GPU (v2.18.0) conda environment, and
    - Submits `sensorflow-long.py` (a production-style, resumable training loop), or `sensorflow-short.py` (is a standalone illustration); Python TensorFlow scripts that:
    - Load and slice datasets that consists of simple feed-forward networks, and
    - Set up checkpointed callback mechanisms that manage saving/loading of model states via Keras callbacks and load_weights logic.
 
---

*We’ve covered Application-Level Checkpointing (handled in the application code, itself) and checkpointing through submit script code modification via BASH. Last, we’ll look at how to setup your own checkpointing mechanism with a separate piece of software (DMTCP)*.
 
---

## Checkpointing with DMTCP:
[DMTCP](https://github.com/dmtcp/dmtcp) (Distributed MultiThreaded Checkpointing) transparently checkpoints a single-host or distributed computation to disk, in user-space. It works with no modifications to the Linux kernel nor to the application binaries. It can be used by unprivileged users (no root privilege needed) - the newest version is installed as a module on BigSky and Skyline ( currently `dmtcp/3.2.0-qr37nrg` ). You can later restart from a checkpoint or even migrate processes by moving the checkpoint files to another host prior to restarting.
 
- DMTCP can be invoked via calling the module in an sbatch script or invoked from the command line, there’s a test-set of data (array/C++ code) and a pre-written submit script (with included wrapper-script) here:
  ```bash
  /data/user-utils/user-scripts/checkpointing/dmtcp
  ```

- `/DMTCP` (contains 4 files that are intended to work in-tandem and should reside in the same directory, including a test-set of data (array/C++ code) and a pre-written submit script (with included wrapper-script)
  - `dmtcp-array.sbatch`
    - Loads the dmtcp module, 
    - Starts a DMTCP coordinator process (small background service) listening on TCP port 7779, 
    - Runs the `example.cpp` code on `example_array`, and
    - Monitors the program, saving periodic checkpoint images of the process and exits cleanly when finished.
    - `mumble-wrapper.sh` is a wrapper script that can be used to submit 10,000 tasks in chunks of 2000 each, with 10 running at a time.
 
*It’s worth noting - by default, DMTCP uses gzip to compress the checkpoint images. This can be turned off (`dmtcp_launch --no-gzip` ; or setting an environment variable to `0: DMTCP_GZIP=0`). This will be faster, and if your memory is dominated by incompressible data, this can be helpful. Gzip can add seconds for large checkpoint images. Typically, checkpoints and restarts are less than one second without gzip*.
 
---

## DMTCP Demonstration/Walkthrough
 
The general workflow consists of 2 main components, the **Coordinator** and the **Launcher**:
 
#### Coordinator
1. SSH to a submit node and use srun to submit a SLURM job - specifically to the host/location where you want to run your program (optional: start a new tmux session here if you’d like - e.g., `$ tmux new -s dmtcp-coordinator`)
   ```bash
   [user@host ~]$ srun -p gpu -w host -c 16 --mem 4G --pty bash
   ```

2. Load the DMTCP module and launch a DMTCP coordinator (the default behavior is manual checkpointing using the `[c]` keystroke, however, you can specify an automatic checkpoint interval using the `-i <time_in_seconds>` flag):
   ```bash
   [user@host ~]$ ml dmtcp && dmtcp_launch --version
   dmtcp_launch (DMTCP) 3.2.0
 
   [user@host ~]$ dmtcp_coordinator
   dmtcp_coordinator starting...
       Host: host.domain.foo.bar (10.140.218.143)
       Port: 7779
       Checkpoint Interval: disabled (checkpoint manually instead)
       Exit on last client: 0
   Type '?' for help.
 
   [2025-04-23T13:55:12.667, 125367, 125367, Note] at coordinatorplugin.h:205 in tick; REASON='No active clients; starting stale timeout
        theStaleTimeout = 28800
 
   dmtcp>
   ```
   
#### Launcher
3. SSH to a submit node and use srun to submit a SLURM job specifically to the same host/location where you started your coordinator:
   ```bash
   [user@host ~]$ srun -p gpu -w host -c 32 --mem 8G --pty bash
   ```
4. Load the DMTCP module and launch your application using DMTCP (you must use the `--join-coordinator` flag to connect to your coordinator instance) - (`dmtcp_launch <flags> <command>`)
   ```bash
   [user@host ~]$ ml dmtcp && dmtcp_launch --version
   
   [user@host ~]$ dmtcp_launch --join-coordinator ./p-dd.sh
   Running: dd iflag=fullblock if=/dev/zero of=/data/scratch/user/1-1G bs=1G count=1
   1+0 records in
   1+0 records out
   1073741824 bytes (1.1 GB, 1.0 GiB) copied, 0.525024 s, 2.0 GB/s
 
#### Coordinator
5. On your coordinator window, you can begin to track the process as it connects and exchanges process information after execution of various components (press `[s]` then `[enter]` for a status):
   ```bash
   [2025-04-23T14:13:34.398, 126044, 126044, Note] at dmtcp_coordinator.cpp:919 in onConnect; REASON='worker connected
         hello_remote.from = 40f5a9a622088167-64000-10deccda2e4203
         client->progname() = bash_(forked)
   [2025-04-23T14:13:34.398, 126044, 126044, Note] at dmtcp_coordinator.cpp:680 in onData; REASON='Updating process Information after fork()
         client->hostname() = host.domain.foo.bar
         client->progname() = bash_(forked)
         msg.from = 40f5a9a622088167-65000-10deccda34fc14
         client->identity() = 40f5a9a622088167-40000-10dec20e3d5513
   [2025-04-23T14:13:34.399, 126044, 126044, Note] at dmtcp_coordinator.cpp:680 in onData; REASON='Updating process Information after fork()
         client->hostname() = host.domain.foo.bar
         client->progname() = bash_(forked)
         msg.from = 40f5a9a622088167-66000-10deccda3eb86c
         client->identity() = 40f5a9a622088167-64000-10deccda2e4203
   [2025-04-23T14:13:34.439, 126044, 126044, Note] at dmtcp_coordinator.cpp:689 in onData; REASON='Updating process Information after exec()
         progname = dd
         msg.from = 40f5a9a622088167-66000-10deccda3eb86c
         client->identity() = 40f5a9a622088167-66000-10deccda3eb86c
   [2025-04-23T14:13:34.439, 126044, 126044, Note] at dmtcp_coordinator.cpp:689 in onData; REASON='Updating process Information after exec()
         progname = tee
         msg.from = 40f5a9a622088167-65000-10deccda34fc14
   client->identity() = 40f5a9a622088167-65000-10deccda34fc14
 
   dmtcp> s
   Status...
   Host: host.domain.foo.bar (10.140.218.143)
   Port: 7779
   Checkpoint Interval: Checkpoint Interval: disabled (checkpoint manually instead)
   Exit on last client: 0
   Kill after checkpoint: 0
   Computation Id: 40f5a9a622088167-40000-10e45ea0c96acd
   Checkpoint Dir: /data/home/user
   NUM_PEERS=4
   RUNNING=yes
   ```
   
6. You can manually checkpoint your running job at any time by pressing the `[c]` key, the most important part of the output being the <mark>*path to the restart script*</mark>. A new restart script is written after each successful checkpoint file is created:
   ```bash
   dmtcp> c
   [2025-04-23T14:15:52.263, 126044, 126044, Note] at dmtcp_coordinator.cpp:1164 in startCheckpoint; REASON='starting checkpoint; incrementing generation; suspending all nodes
         s.numPeers = 4
         compId.computationGeneration() = 1
   [2025-04-23T14:15:53.086, 126044, 126044, Note] at dmtcp_coordinator.cpp:496 in releaseBarrier; REASON='Checkpoint complete; all workers running
   [2025-04-23T14:15:53.174, 126044, 126044, Note] at dmtcp_coordinator.cpp:559 in recordCkptFilename; REASON='Checkpoint complete. Wrote restart script
         restartScriptPath = /data/home/user/dmtcp_restart_script_40f5a9a622088167-40000-10dec2040da13b.sh
   ```
   ```bash
   restartScriptPath = /data/home/user/dmtcp_restart_script_40f5a9a622088167-40000-10dec2040da13b.sh
   ```
   
---

**$${\color{red}“OH \space NO, \space MY \space JOB!”}$$**

*If your job is cancelled, terminated unexpectedly or purposefully, your SSH session is broken or stale, etc. etc. - you can srun back to your launcher instance and run the provided script directly to restart your job from the checkpoint (below)*

---

#### Coordinator
DMTCP Coordinator showing the process being forcibly cancelled, client disconnected, and the stale timeout timer started:
   ```bash
   [2025-04-23T14:18:07.234, 126044, 126044, Note] at dmtcp_coordinator.cpp:689 in onData; REASON='Updating process Information after exec()
         progname = dd
         msg.from = 40f5a9a622088167-87000-10df0c5e0f9761
         client->identity() = 40f5a9a622088167-87000-10df0c5e0f9761
   [2025-04-23T14:19:29.014, 126044, 126044, Note] at dmtcp_coordinator.cpp:775 in onDisconnect; REASON='client disconnected
         client->identity() = 40f5a9a622088167-86000-10df0c5e08ffc1
         client->progname() = tee
   [2025-04-23T14:19:54.078, 126044, 126044, Note] at dmtcp_coordinator.cpp:775 in onDisconnect; REASON='client disconnected
         client->identity() = 40f5a9a622088167-87000-10df0c5e0f9761
         client->progname() = dd
   [2025-04-23T14:19:54.701, 126044, 126044, Note] at dmtcp_coordinator.cpp:775 in onDisconnect; REASON='client disconnected
         client->identity() = 40f5a9a622088167-85000-10df0c5dfedd8a
         client->progname() = bash_(forked)
   [2025-04-23T14:19:55.772, 126044, 126044, Note] at dmtcp_coordinator.cpp:775 in onDisconnect; REASON='client disconnected
         client->identity() = 40f5a9a622088167-40000-10dec20e3d5513
         client->progname() = bash
   [2025-04-23T14:19:56.775, 126044, 126044, Note] at coordinatorplugin.h:205 in tick; REASON='No active clients; starting stale timeout
         theStaleTimeout = 28800
   ```

#### Launcher
Showing the job being restarted by *instantiating* our DMTCP restart script ( `./dmtcp_restart_script_ckptID.sh` ):
   ```bash
   [user@host ~]$ /data/home/user/dmtcp_restart_script_40f5a9a622088167-40000-10dec2040da13b.sh
   . . .
   1000+0 records in
   1000+0 records out
   1073741824000 bytes (1.1 TB, 1000 GiB) copied, 269.9 s, 3.8 GB/s
   . . .
   ```

#### Coordinator
Showing computational reset and connection
   ```bash
   [2025-04-23T14:20:43.980, 126044, 126044, Note] at dmtcp_coordinator.cpp:811 in initializeComputation; REASON='Resetting computation
   [2025-04-23T14:20:43.981, 126044, 126044, Note] at dmtcp_coordinator.cpp:995 in validateRestartingWorkerProcess; REASON='FIRST restart connection. Set numRestartPeers. Generate timestamp
         numRestartPeers = 4
         curTimeStamp = 4749000625441924
         compId = 40f5a9a622088167-40000-10dec2040da13b
   [2025-04-23T14:20:43.981, 126044, 126044, Note] at dmtcp_coordinator.cpp:919 in onConnect; REASON='worker connected
         hello_remote.from = 40f5a9a622088167-40000-10dec20e3d5513
         client->progname() = bash
   [2025-04-23T14:20:43.986, 126044, 126044, Note] at dmtcp_coordinator.cpp:919 in onConnect; REASON='worker connected
         hello_remote.from = 40f5a9a622088167-64000-10deccda2e4203
         client->progname() = bash
   [2025-04-23T14:20:43.986, 126044, 126044, Note] at dmtcp_coordinator.cpp:919 in onConnect; REASON='worker connected
         hello_remote.from = 40f5a9a622088167-65000-10deccda34fc14
         client->progname() = tee
   [2025-04-23T14:20:43.989, 126044, 126044, Note] at dmtcp_coordinator.cpp:919 in onConnect; REASON='worker connected
         hello_remote.from = 40f5a9a622088167-66000-10deccda3eb86c
         client->progname() = dd
   ```

---
