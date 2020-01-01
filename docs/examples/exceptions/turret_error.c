// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020 Joel E. Anderson
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
#include <turret_error.h>

static struct turret_error jammed_instance = {
  .code = JAMMED,
  .message = "ah crap, the turret jammed!"
};

static struct turret_error out_of_ammo_instance = {
  .code = OUT_OF_AMMO,
  .message = "the turret is out of ammo, reload!"
};

static struct turret_error success_instance = {
  .code = SUCCESS,
  .message = "operation success"
};

static struct turret_error targeting_error_instance = {
  .code = TARGETING_ERROR,
  .message = "I can't aim at the fourth quadrant..."
};

const char *
get_error_message( const struct turret_error *err ) {
  return err->message;
}

struct turret_error *
jammed( void ) {
  return &jammed_instance;
}

struct turret_error *
null_error( void ) {
  return NULL;
}

struct turret_error *
out_of_ammo( void ) {
  return &out_of_ammo_instance;
}

struct turret_error *
success( void ) {
  return &success_instance;
}

struct turret_error *
targeting_error( void ) {
  return &targeting_error_instance;
}
