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

const struct turret_error *
out_of_ammo( void );

const struct turret_error *
success( void );

#endif
