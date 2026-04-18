/**
 * Logic for job and task management.
 *
 * You are not required to modify this file.
 */

#include "job.h"

job_t* job_create(submit_job_request* argp, int job_id) {
    job_t* job = malloc(sizeof(job_t));
    job->job_id = job_id;
    job->output_dir = strdup(argp->output_dir);
    job->app = strdup(argp->app);
    job->n_reduce = argp->n_reduce;
    job->n_map = argp->files.files_len;
    job->files = malloc(sizeof(char*) * job->n_map);
    for (int i = 0; i < job->n_map; i++) {
      job->files[i] = strdup(argp->files.files_val[i]);
    }
    job->map_tasks = calloc(job->n_map, sizeof(int));
    job->reduce_tasks = calloc(job->n_reduce, sizeof(int));
    job->status = JOB_MAPPING;
    job->args_len = argp->args.args_len;
    job->args = malloc(job->args_len);
    memcpy(job->args, argp->args.args_val, job->args_len);
    return job;
  }
  

bool job_all_maps_done(job_t* job) {
    for (int i = 0; i < job->n_map; i++) {
        if (job->map_tasks[i] != -1) return false;
    }
    return true;
}

bool job_all_reduces_done(job_t* job) {
    for (int i = 0; i < job->n_reduce; i++) {
        if (job->reduce_tasks[i] != -1) return false;
    }
    return true;
}

void update_map_task_timeout(job_t* job) {
    for (int i = 0; i < job->n_reduce; i++) {
        if (job->reduce_tasks[i] > 0 &&
            time(NULL) - job->reduce_tasks[i] > TASK_TIMEOUT_SECS) {
            job->reduce_tasks[i] = 0;
        }
    }
}


void update_reduce_task_timeout(job_t* job) {
    for (int i = 0; i < job->n_reduce; i++) {
        if (job->reduce_tasks[i] > 0 &&
            time(NULL) - job->reduce_tasks[i] > TASK_TIMEOUT_SECS) {
            job->reduce_tasks[i] = 0;
        }
    }
}