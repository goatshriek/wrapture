// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2025 Joel E. Anderson
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

#include <limits.h>

int cmakeclib_add( int n1, int n2 ){
  int result = n1 + n2;

  if( n1 < 0 && n2 < 0 && (result > n1 || result > n2 ) ){
    result = INT_MIN;
  } else if( n1 > 0 && n2 > 0 && (result < n1 || result < n2 ) ){
    result = INT_MAX;
  }

  return result;
}
