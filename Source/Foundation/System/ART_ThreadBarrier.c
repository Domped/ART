


#define ART_MODULE_NAME     ART_ThreadBarrier

#include "ART_ThreadBarrier.h"

int art_pthread_barrier_init(art_pthread_barrier_t *barrier, unsigned int count)
{
    if (count == 0) {
        return -1;
    }

    int ret;

    // Initialize mutex
    ret = pthread_mutex_init(&barrier->mutex, NULL);
    if (ret != 0) {
        return ret; // Return mutex init error
    }

    // Initialize condition variable
    ret = pthread_cond_init(&barrier->cond, NULL);
    if (ret != 0) {
        if(&barrier->mutex) {
            pthread_mutex_destroy(&barrier->mutex);
        }
        return ret; // Return condition variable init error
    }

    // Initialize barrier state
    barrier->threshold = count;
    barrier->count = 0;
    barrier->cycle = 0;

    return 0; // Success
}

int art_pthread_barrier_destroy(art_pthread_barrier_t *barrier)
{
    if (barrier == NULL) {
        return -1;
    }

    int status = pthread_mutex_lock(&barrier->mutex);
    if (status != 0) {
        return status;
    }

    // Check if any threads are currently waiting inside the barrier
    if (barrier->count != 0) {
        pthread_mutex_unlock(&barrier->mutex);
        return -1; // Cannot destroy barrier while threads are using it
    }

    // Unlock before destroying mutex itself
    pthread_mutex_unlock(&barrier->mutex);

    int status_cond, status_mutex;

    status_cond = pthread_cond_destroy(&barrier->cond);
    status_mutex = pthread_mutex_destroy(&barrier->mutex);

    if (status_cond != 0) {
        return -1;
    }

    return 0; // Will be 0 if both succeeded
}
int art_pthread_barrier_wait(art_pthread_barrier_t *barrier)
{
    if (barrier == NULL) {
        return -1;
    }

    int status = pthread_mutex_lock(&barrier->mutex);
    if (status != 0) {
        return status;
    }
    // Store the current cycle number. Threads wait until the cycle advances.
    unsigned int current_cycle = barrier->cycle;

    // Increment the count of waiting threads
    barrier->count++;

    if (barrier->count == barrier->threshold) {
        barrier->count = 0;
        barrier->cycle++;

        status = pthread_cond_broadcast(&barrier->cond);

        int unlock_status = pthread_mutex_unlock(&barrier->mutex);
        if (status != 0) return status;
        if (unlock_status != 0) return unlock_status; // Report unlock error

        // This thread is the "serial" thread for this barrier wait cycle
        return 1;
    } else {
        while (barrier->cycle == current_cycle) {
            status = pthread_cond_wait(&barrier->cond, &barrier->mutex);
            if (status != 0) {
                pthread_mutex_unlock(&barrier->mutex);
                return -1;
            }
        }

        status = pthread_mutex_unlock(&barrier->mutex);
        return status;
    }
}