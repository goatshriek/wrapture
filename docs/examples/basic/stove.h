/* SPDX-License-Identifier: Apache-2.0 */

/*
 * Copyright 2026 Joel E. Anderson
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

#ifndef __STOVE_H
#define __STOVE_H

#  ifdef __cplusplus
extern "C" {
#  endif

struct stove {
  int burner_count;
  int *burner_levels;
  int oven_temp;
};

struct stove *new_stove( int burner_count );
int get_burner_count( struct stove *s );
int get_burner_level( struct stove *s, int burner );
void set_burner_level( struct stove *s, int burner, int level );
int get_oven_temp( struct stove *s );
void set_oven_temp( struct stove *s, int new_temp);
void destroy_stove( struct stove *s );

int is_model_supported( int model );

#  ifdef __cplusplus
}
#  endif

#endif
