/* ===========================================================================

    Copyright (c) The ART Development Team
    --------------------------------------

    For a comprehensive list of the members of the development team, and a
    description of their respective contributions, see the file
    "ART_DeveloperList.txt" that is distributed with the libraries.

    This file is part of the Advanced Rendering Toolkit (ART) libraries.

    ART is free software: you can redistribute it and/or modify it under the
    terms of the GNU General Public License as published by the Free Software
    Foundation, either version 3 of the License, or (at your option) any
    later version.

    ART is distributed in the hope that it will be useful, but WITHOUT ANY
    WARRANTY; without even the implied warranty of MERCHANTABILITY or
    FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
    for more details.

    You should have received a copy of the GNU General Public License
    along with ART.  If not, see <http://www.gnu.org/licenses/>.

=========================================================================== */
#ifndef _ART_FOUNDATION_SYSTEM_ART_THREAD_BARRIER_
#define _ART_FOUNDATION_SYSTEM_ART_THREAD_BARRIER_

#include <pthread.h>
#include <errno.h> // For error codes like EINVAL


typedef struct {
    pthread_mutex_t mutex;
    pthread_cond_t cond;
    unsigned int threshold;
    unsigned int count;
    unsigned int cycle;
} art_pthread_barrier_t;

// Function prototypes matching the POSIX barrier API
int art_pthread_barrier_init(art_pthread_barrier_t *barrier, unsigned int count);
int art_pthread_barrier_destroy(art_pthread_barrier_t *barrier);
int art_pthread_barrier_wait(art_pthread_barrier_t *barrier);

#endif

