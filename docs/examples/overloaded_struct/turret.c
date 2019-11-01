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

#include <turret.h>
#include <turret_error.h>

static int ammo_count = 10;

const struct turret_error *
aim( int x, int y, int z ) {
  return success();
}

const struct turret_error *
fire( void ) {
  if( ammo_count > 0 ) {
    ammo_count -= 1;
    return success();
  } else {
    return out_of_ammo();
  }
}

const struct turret_error *
reload( void ) {
  ammo_count = 10;
  return success();
}
