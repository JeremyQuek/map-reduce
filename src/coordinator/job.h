/**
 * Logic for job and task management.
 *
 * You are not required to modify this file.
 */

#ifndef JOB_H__
#define JOB_H__

#include <stdbool.h>
#include <time.h>

#include "../lib/lib.h"
#include "../rpc/rpc.h"

/* You may add definitions here */

typedef enum {
    JOB_MAPPING,
    JOB_REDUCING,
    JOB_DONE,
    JOB_FAILED
} job_status;

typedef struct {
    int job_id;
    char** files;   
    char* output_dir;
    char* app;

    char* args;
    int args_len;

    int n_reduce;
    int n_map; 

    // 0=idle, -1=done, >0=timestamp when assigned
    int* map_tasks;
    int* reduce_tasks;

    job_status status;
} job_t;

job_t* job_create(submit_job_request* argp, int job_id);
bool job_all_maps_done(job_t* job);
bool job_all_reduces_done(job_t* job);
void update_map_task_timeout(job_t* job);
void update_reduce_task_timeout(job_t* job);
#endif
