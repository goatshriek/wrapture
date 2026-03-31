// SPDX-License-Identifier: Apache-2.0

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

#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>
#include <stove.h>

struct stove *
new_stove( int burner_count ) {
  struct stove *result;
  size_t levels_size;
  int i;

  result = ( struct stove * ) malloc( sizeof( *result ) );
  if( !result ) {
    return NULL;
  }

  levels_size = sizeof( *result->burner_levels ) * burner_count;
  result->burner_levels = ( int * ) malloc( levels_size );
  if( !result->burner_levels ) {
    return NULL;
  }

  for( i = 0; i < burner_count; i++ ) {
    result->burner_levels[i] = 0;
  }

  result->burner_count = burner_count;
  result->oven_temp = 0;

  printf( "created a new stove with %d burners\n", burner_count );

  return result;
}

int
get_burner_count( struct stove *s ) {
  return s->burner_count;
}

int
get_burner_level( struct stove *s, int burner ) {
  return s->burner_levels[burner];
}

void
set_burner_level( struct stove *s, int burner, int level ) {
  s->burner_levels[burner] = level;

  printf( "set burner %d to %d\n", burner, level );
}

int
get_oven_temp( struct stove *s ) {
  return s->oven_temp;
}

void
set_oven_temp( struct stove *s, int new_temp ) {
  s->oven_temp = new_temp;

  printf( "set oven temp to %d\n", new_temp );
}

void
destroy_stove( struct stove *s ) {
  printf( "destroyed a stove\n" );

  free( s->burner_levels );
  free( s );
}

int
is_model_supported( int model ) {
  return model > 2 && model <= 5;
}
