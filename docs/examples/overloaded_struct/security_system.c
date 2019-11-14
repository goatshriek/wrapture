// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2019 Joel E. Anderson
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <inttypes.h>
#include <security_system.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

static int event_type = 0;
static int break_level = 3;

struct event *
copy_event( struct event *ev ) {
  return new_event( ev->code, ev->data );
}

void
destroy_event( struct event *ev ) {
  if( ev->code == GLASS_BREAK_EVENT ) {
    free( ev->data );
  }

  free( ev );
}

struct event *
get_next_event( void ) {
  switch( event_type++ % 3 ) {
    case 0:
      return new_motion_event( "watch out for snakes!" );

    case 1:
      return new_glass_break_event( break_level++ );

    case 2:
      return new_camera_event( "is that bigfoot?" );
  }
}

struct event *
new_camera_event( const char *description ) {
  return new_event( CAMERA_EVENT, (void *) description );
}

struct event *
new_default_event( void ) {
  return new_event( 0, NULL );
}

struct event *
new_event( int code, void *data ) {
  struct event *ev;

  ev = (struct event *) malloc( sizeof( *ev ) );
  if( !ev ) {
    return NULL;
  }

  ev->code = code;
  ev->data = data;

  return ev;
}

struct event *
new_glass_break_event( int level ) {
  return new_event( GLASS_BREAK_EVENT, ( void * ) ( (uintptr_t) level ) );
}

struct event *
new_motion_event( const char *description ) {
  return new_event( MOTION_EVENT, (void *) description );
}

void
print_event( const struct event *ev ) {
  printf( "event code: %d\n", ev->code );
}

void
print_camera_event( const struct event *ev ) {
  printf( "camera event: %s\n", (char *) ev->data );
}

void
print_glass_break_event( const struct event *ev ) {
  printf( "glass break event: level %" PRIxPTR "\n", (uintptr_t) ev->data );
}

void
print_motion_event( const struct event *ev ) {
  printf( "motion event: %s\n", (char *) ev->data );
}
