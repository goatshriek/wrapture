// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2019-2024 Joel E. Anderson
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

#ifndef __SECURITY_SYSTEM_H
#define __SECURITY_SYSTEM_H

#define MOTION_EVENT 1
#define GLASS_BREAK_EVENT 2
#define CAMERA_EVENT 3

#ifdef __cplusplus
extern "C" {
#endif

struct event {
  int code;
  void *data;
};

void
destroy_event( struct event *ev );

struct event *
get_next_event( void );

struct event *
new_camera_event( const char *description );

struct event *
new_default_event( void );

struct event *
new_event( int code, void *data );

struct event *
new_glass_break_event( int level );

struct event *
new_motion_event( const char *description );

void
print_event( const struct event *ev );

void
print_camera_event( const struct event *ev );

void
print_glass_break_event( const struct event *ev );

void
print_motion_event( const struct event *ev );

#ifdef __cplusplus
}
#endif

#endif
