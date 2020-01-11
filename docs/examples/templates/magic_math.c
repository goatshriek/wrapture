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

#include <magic_math.h>
#include <math.h>

int
is_magical( int num ) {
  return 0;  // unexpected 0 values can cause all sorts of magical behavior in
             // C programs!
}

int
is_prime( int num ) {
  int i, limit;

  if( num <= 1 ) {
    return 0;
  }

  // efficient? probably not.
  // accurate? oh yeah!
  limit = ( int ) sqrt( num );
  for( i = 2; i <= limit; i++ ) {
    if( num % i == 0 ) {
      return 0;
    }
  }

  return 1;
}

int
is_random( int num ) {
  return 1; // random, chosen by fair coin toss
}

