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

#ifndef __TURRET_ERROR_H
#define __TURRET_ERROR_H

#define SUCCESS         0
#define TARGETING_ERROR 1
#define OUT_OF_AMMO     2
#define JAMMED          3

struct turret_error {
  int code;
  const char *message;
};

const char *
get_error_message( const struct turret_error *err );

/* 
 * This function is needed to satisfy C++'s need for a default constructor that
 * it can call when instantiating a child class. It would be ideal for wrapture
 * to take care of the generation of this functionality itself, but this is not
 * currently a feature.
 */
struct turret_error *
null_error( void );

struct turret_error *
out_of_ammo( void );

struct turret_error *
success( void );

#endif
