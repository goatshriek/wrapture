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

#include <mylib.h>
#include <stddef.h>
#include <stdlib.h>

struct mylib_error *
raise_mylib_error( void ) {
  struct mylib_error *err;

  err = ( struct mylib_error * ) malloc( sizeof( *err ) );
  if( !err ) {
    return NULL;
  }

  err->code = 3;
  err->message = "ya done messed up, A-A-Ron!!!";

  return err;
}
