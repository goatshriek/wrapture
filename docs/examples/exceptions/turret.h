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

#ifndef __TURRET_H
#define __TURRET_H

#include <turret_error.h>

struct turret {
  int ammo_count;
  int x;
  int y;
  int z;
};

struct turret_error *
aim( struct turret *t, int x, int y, int z );

int
ammo_count( struct turret *t );

void
destroy_turret( struct turret *t );

struct turret_error *
fire( struct turret *t );

struct turret *
new_turret( void );

struct turret_error *
reload( struct turret *t );

#endif
