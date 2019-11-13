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

#include <security_event.h>
#include <stdio.h>
#include <stdlib.h>

static int event_type = 0;
static int break_level = 3;

void
destroy_event( struct event *ev ) {
  if( ev->code == GLASS_BREAK_EVENT ) {
    free( ev->data );
  }

  free( ev );
}

struct event *
get_next_event( void ) {
  struct event *next;

  next = malloc( sizeof( *next ) );
  if( !next ) {
    return NULL;
  }

  switch( event_type++ % 3 ) {
    case 0:
      next->code = MOTION_DETECTOR_EVENT;
      next->data = "watch out for snakes!";
      break;

    case 1:
      next->data = malloc( sizeof( break_level ) );
      if( !next->data ) {
        free( next);
        return NULL;
      }

      next->code = GLASS_BREAK_EVENT;
      break_level++;
      *next->data = break_level;
      break;

    case 2:
      next->code = CAMERA_EVENT;
      next->data = "is that bigfoot?";
      break;
  }

  return next;
}

struct event *
new_camera_event( const char *description ) {

}

struct event *
new_event( int code, void *data ) {

}

struct event *
new_glass_break_event( int level ) {

}

struct event *
new_motion_event( const char *description ) {

}

void
print_event( const struct event *ev ) {
  printf( "event code: %d\n", ev->code );
}

void
print_camera_event( const struct event *ev ) {
  printf( "camera event: %s\n", ev->data );
}

void
print_glass_break_event( const struct event *ev ) {
  printf( "glass break event: level %d\n", *ev->data );
}

void
print_motion_event( const struct event *ev ) {
  printf( "motion event: %s\n", ev->data );
}
