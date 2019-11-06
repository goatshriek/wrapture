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

#ifndef __SECURITY_SYSTEM_H
#define __SECURITY_SYSTEM_H

#define MOTION_DETECTOR_EVENT 1
#define GLASS_BREAK_EVENT 2
#define CAMERA_EVENT 3

struct event {
  int code;
  void *data;
};

struct event *
get_next_event( void );

void
print_event( const struct event *ev );

#endif
