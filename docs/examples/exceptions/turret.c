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

#include <stdlib.h>
#include <turret.h>
#include <turret_error.h>

const struct turret_error *
aim( struct turret *t, int x, int y, int z ) {
  return success();
}

void
destroy_turret( struct turret *t ) {
  free( t );
}

const struct turret_error *
fire( struct turret *t ) {
  if( t->ammo_count > 0 ) {
    t->ammo_count -= 1;
    return success();
  } else {
    return out_of_ammo();
  }
}

struct turret_error *
new_turret( void ) {
  struct turret *t;

  t = malloc( sizeof( *t ) );
  if( !t ) {
    return NULL;
  }

  t->ammo_count = 10;

  return t;
}

const struct turret_error *
reload( struct turret *t ) {
  t->ammo_count = 10;
  return success();
}
