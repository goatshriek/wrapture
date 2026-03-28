// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2023-2026 Joel E. Anderson
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

#include <cstdlib>
#include <iostream>
#include <Stove.hpp>

using namespace std;
using namespace kitchen;

/**
 * Demonstrates the usage of a simple C library which has been wrapped in C++
 * by Wrapture.
 */
int main( int argc, char **argv ) {
  if( Stove::IsModelSupported( 4 ) ) {
    cout << "model 4 stoves are supported" << endl;
  } else {
    cerr << "model 4 stoves are not supported!" << endl;
    return EXIT_FAILURE;
  }

  Stove my_stove (4);
  int burner_count = my_stove.GetBurnerCount();
  cout << "burner count is: " << burner_count << endl;
  if( burner_count != 4 ){
    cerr << "the burner count was not 4!" << endl;
    return EXIT_FAILURE;
  }

  my_stove.SetOvenTemp( 350 );
  int oven_temp = my_stove.GetOvenTemp();
  cout << "current oven temp is: " << oven_temp << endl;
  if( oven_temp != 350 ){
    cerr << "the oven temp was not 350!" << endl;
    return EXIT_FAILURE;
  }

  my_stove.SetBurnerLevel( 2, 9 );
  int burner_level = my_stove.GetBurnerLevel( 2 );
  cout << "burner 2 level is: " << burner_level << endl;
  if( burner_level != 9 ){
    cerr << "the level of burner 2 was not 9!" << endl;
    return EXIT_FAILURE;
  }

  return EXIT_SUCCESS;
}
