# 5G Authorization Platform Simulator

A multi-process, multi-threaded simulation of a 5G data authorization platform, written in C
for the Operating Systems course (2nd year, 2nd semester) of the Informatics Engineering degree
at the University of Coimbra.

The system models a mobile network operator that authorizes data usage requests (video, music
and social media) from mobile users against a per-user data allowance (the "plafond"). It is
built entirely on top of classic UNIX inter-process communication and synchronization
primitives.

## Overview

The platform is composed of three independent executables that cooperate through shared system
resources:

| Executable          | Role                                                                 |
| ------------------- | -------------------------------------------------------------------- |
| `5g_auth_platform`  | System Manager. Orchestrates the whole simulation.                   |
| `mobile_user`       | Simulates a mobile user that issues data authorization requests.     |
| `backoffice_user`   | Administration console for querying and resetting usage statistics.  |

### How it works

1. The **System Manager** reads a configuration file, sets up all shared resources
   (shared memory, semaphores, message queue, named pipes), and spawns the internal processes
   and threads.
2. **Mobile users** connect through a named pipe (`USER_PIPE`) to register, then send data
   requests of three kinds: **V**ideo, **M**usic and **S**ocial.
3. The **Authorization Request Manager (ARM)** receives requests through a receiver thread,
   places them on one of two priority queues (a dedicated video queue and a queue for the other
   request types), and a sender thread dispatches them to the available authorization engines.
4. **Authorization Engines** process requests, simulate processing time, and update each user's
   consumed allowance in shared memory. An extra engine can be deployed dynamically when the
   queues become congested.
5. The **Monitor Engine** watches per-user consumption and notifies users when they reach 80%,
   90% and 100% of their allowance.
6. The **Backoffice user** connects through a separate named pipe (`BACK_PIPE`) and message
   queue to request aggregated statistics or to reset them.

All activity is timestamped and recorded in a shared `log.txt` file, guarded by a semaphore.

## Concepts demonstrated

- Process creation and management (`fork`, `exec`, `wait`)
- POSIX threads, mutexes and condition variables
- Named semaphores and shared-memory semaphores
- System V shared memory and message queues
- Named pipes (FIFOs) and anonymous pipes
- Signal handling and graceful shutdown
- Lock files to prevent multiple instances
- Producer/consumer and priority-queue patterns

## Repository structure

```
.
├── Makefile                 # Build for all three executables
├── README.md
├── bin/                     # Compiled executables (generated)
├── build/                   # Object files (generated)
├── config/
│   └── configuration.conf   # Default simulation parameters
├── docs/
│   ├── Assignment_Spec_2023_2024.pdf   # Original assignment statement
│   ├── Final_Diagram.pdf               # Architecture diagram
│   └── Final_Report.pdf                # Project report
├── include/
│   ├── global.h             # Shared types, globals and configuration macros
│   ├── queue.h              # Request and queue definitions
│   └── system_functions.h   # System Manager function prototypes
└── src/
    ├── system_manager.c         # Entry point of the System Manager
    ├── system_initialization.c  # Config parsing and startup sequence
    ├── structures_creation.c    # Creation of IPC resources and child processes
    ├── arm_threads.c            # Authorization Request Manager (sender/receiver)
    ├── auth_engine.c            # Authorization engine processes
    ├── monitor_engine.c         # Usage monitoring and user notifications
    ├── general_functions.c      # Logging, timing and display helpers
    ├── clean_up.c               # Signal handling and resource cleanup
    ├── queue.c                  # Priority queue implementation
    ├── mobile_user.c            # Mobile user client
    └── backoffice_user.c        # Backoffice administration client
```

## Building

Requires `gcc` and a POSIX system (Linux). From the repository root:

```sh
make
```

This produces three executables in `bin/`. To remove all build artifacts:

```sh
make clean
```

## Configuration

The simulation is driven by a configuration file containing six positive integers, one per line.
The order is fixed:

| Line | Parameter         | Meaning                                                       |
| ---- | ----------------- | ------------------------------------------------------------- |
| 1    | `MOBILE_USERS`    | Maximum number of simultaneous mobile users                   |
| 2    | `QUEUE_POS`       | Number of slots in each request queue                         |
| 3    | `AUTH_SERVERS`    | Maximum number of authorization engines                       |
| 4    | `AUTH_PROC_TIME`  | Time (ms) an engine takes to process a request                |
| 5    | `MAX_VIDEO_WAIT`  | Maximum wait (ms) for a video request before being processed  |
| 6    | `MAX_OTHERS_WAIT` | Maximum wait (ms) for a non-video request before processing   |

A sample file is provided at `config/configuration.conf`.

## Running

Open separate terminals for each component. The System Manager must be started first.

1. Start the System Manager with a configuration file:

   ```sh
   ./bin/5g_auth_platform config/configuration.conf
   ```

2. Start one or more mobile users. Arguments:
   `plafond max_requests delta_video delta_music delta_social data_amount`

   ```sh
   ./bin/mobile_user 1000 50 200 200 200 100
   ```

3. Start the backoffice console (takes no arguments):

   ```sh
   ./bin/backoffice_user
   ```

   Available commands inside the console:
   - `data_stats` - print current consumption statistics
   - `reset` - reset the statistics
   - `exit` - leave the console

Only one instance of the System Manager can run at a time; a lock file in `/tmp` enforces this.
Use `Ctrl+C` on the System Manager to trigger a graceful shutdown that releases all IPC
resources.

## Compile-time options

A few features can be toggled with macros at the top of `include/global.h`:

- `SLOWMOTION` - slows the simulation down by a fixed coefficient for easier observation.
- `DEBUG` - enables verbose debug output to stdout.
- `QUEUE_PROGRESS_BAR` - displays a progress bar for the request queues.
- `SHARED_MEMORY_DISPLAY` - displays the contents of shared memory (enabled by default).

After changing any of these, rebuild with `make clean && make`.

## Logging

While running, all components append timestamped events to a shared `log.txt` file created in
the working directory. It is removed by `make clean`.

## Authors

- Nuno Batista
- Miguel Castela
