<div align=center>
  <h1 style="margin: 0;"> A MapReduce Implementation
  </h1>
</div>



<div align="center">
<img width="800" height="450" alt="image" src="https://github.com/user-attachments/assets/7aa23b1f-e318-4ca0-92d1-223eefd30e0d" />

</div>

<br/><br/>

A distributed data processing system inspired by [Google's original MapReduce paper](https://static.googleusercontent.com/media/research.google.com/en//archive/mapreduce-osdi04.pdf), built as part of CS 162. 

Obviously, this isn't the cleanest C I've ever written, but I enjoyed implementing this andd learned a ton about distributed systems, RPC protocols, task scheduling, and why fault tolerance is genuinely hard to get right.
<br/><br/>

## What is MapReduce?

MapReduce is a programming model for processing large datasets in parallel across a cluster of machines. There are two primary phases:
 
- **map** — takes an input record, emits a set of key/value pairs
- **reduce** — takes a key and all its values, merges them into a final result

<div align="center">
  <img width="600" height="440" alt="Gemini_Generated_Image_iy7oryiy7oryiy7o" src="https://github.com/user-attachments/assets/4289d7be-e4bb-4e4b-940b-1c785083fe7f" />
</div>
<br/>

In a era of where vertical scaling was limited , MapReduce's goal was to leverage clusters of low-end pcs to parallelize costly tasks.

It does this by distributing the work across a node clusters, each handling a small slice of the data independently, then merging the results

<br/>
<br/>

For instance, if we wanted to **aggregate error logs across 10,000 servers efficiently, we would use** :

- **Map**:  each worker to processe one server's log file, emitting (error_type, 1) for every error it encounters

- **Reduce** :  each reduce worker handle a splice of error keys, and sums all counts and give a global view of errors across the fleet

<br/><br/>

The ingenuity here is master worker's usage of RPC so it appears all computation happens on a single super machine!

<br/><br/>

## Architecture
 
The cluster has three components:
 
- **Coordinator** — the brain. Accepts jobs, schedules tasks, detects failures
- **Workers** — do the actual computation. Poll the coordinator for tasks, execute them, report back
- **Client** — submits jobs via RPC and polls for completion
```
Client  ->  SUBMIT_JOB  ->  Coordinator  ->  GET_TASK  ->  Workers
Client  ->  POLL_JOB   ->  Coordinator                      |
                           Coordinator  <-  FINISH_TASK  <--+
```
 
<br/>

## Why RPC?
 
Workers and the coordinator run as separate processes. RPC (Remote Procedure Calls) lets them communicate as if calling local functions, hiding all the socket and serialization complexity underneath. The coordinator exposes four RPCs:
 
| RPC | Direction | Purpose |
|---|---|---|
| `SUBMIT_JOB` | Client to Coordinator | Queue a new job |
| `POLL_JOB` | Client to Coordinator | Check job status |
| `GET_TASK` | Worker to Coordinator | Request next task |
| `FINISH_TASK` | Worker to Coordinator | Report task done/failed |
 
Workers poll `GET_TASK` every few seconds. The coordinator replies with either a task to execute or a `wait` flag. I found this polling model surprisingly elegant — the coordinator is completely stateless with respect to which worker is alive, it just hands out work to whoever asks.
 
<br/>

## Job Execution Flow
 
**Map phase:**
1. Client submits job with `n` input files, coordinator creates `n` map tasks
2. Workers poll for tasks, each gets assigned one input file
3. Each worker runs the `map` function, writes intermediate key/value pairs to `mr-i-j` files, where `i` = map task number and `j` = reduce bucket (`ihash(key) % n_reduce`)
**Reduce phase:**
 
4. Once all map tasks complete, coordinator switches to reduce phase
5. Each reduce worker `j` reads all `mr-0-j`, `mr-1-j`, ..., `mr-(n_map-1)-j` files
6. Sorts by key, runs `reduce` function on each group, writes final output
The intermediate file naming is deterministic, so workers figure out which files to read themselves. The coordinator never touches the actual data, which I think is the cleanest part of the whole design.
 
<br/>

## Task Scheduling & FIFO Order
 
Multiple jobs can be queued simultaneously. The coordinator maintains a job queue and prioritizes earlier jobs using a two pass scan on every `GET_TASK` call:
 
- **Pass 1:** scan all jobs front-to-back for any idle reduce tasks, assign first found
- **Pass 2:** scan all jobs front-to-back for any idle map tasks, assign first found
This ensures reduce tasks always take priority over map tasks from later jobs, while never leaving workers idle if there's work available anywhere in the queue. The two pass approach is O(n) but with at most a handful of concurrent jobs it's effectively instant.

I reckon that a priority queue sorted on job ID would allow a more robust and efficient FIFO order structure, however for a MVP this works
 
Each task is tracked with a single integer encoding its state:
```
0   = idle
-1  = done
>0  = in progress (unix timestamp of when it was assigned)
```
 
Collapsing state and timestamp into one value was a neat trick that saved a separate timestamp array.
 
<br/>

## Fault Tolerance
 
Workers crash. That's a given in any real distributed system. The coordinator handles this by checking how long each in-progress task has been running. If a worker hasn't reported back within `TASK_TIMEOUT_SECS`, its task is reset to idle and reassigned to the next available worker.
 
```c
if (task[i] > 0 && time(NULL) - task[i] > TASK_TIMEOUT_SECS) {
    task[i] = 0;  // reset to idle, will be reassigned
}
```
 
Completed tasks are never reassigned since their output is already written to disk. If a task reports `success = false` (unrecoverable error like a missing input file or a failed map function), the entire job is marked failed immediately and no further tasks are assigned for it.
 
<br/>

## Running It
 
```bash
# Start coordinator
./bin/mr-coordinator
 
# Start workers (in another terminal)
for i in {1..5}; do (./bin/mr-worker &); done
 
# Submit a word count job
./bin/mr-client submit -a wc -o out -w -n 10 data/gutenberg/*
 
# Process output
./bin/mr-client process -a wc -o out -n 10
```
 
Available apps: `wc` (word count), `grep`, `vertex_degree`
 
