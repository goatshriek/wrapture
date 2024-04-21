// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2023 Joel E. Anderson
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

int main( int argc, char **argv ) {
  if( Stove::IsModelSupported( 4 ) ) {
    cout << "model 4 stoves are supported" << endl;
  }

  Stove my_stove (4);
  cout << "burner count is: " << my_stove.GetBurnerCount() << endl;

  my_stove.SetOvenTemp( 350 );
  cout << "current oven temp is: " << my_stove.GetOvenTemp() << endl;

  my_stove.SetBurnerLevel( 2, 9 );
  cout << "burner 2 level is: " << my_stove.GetBurnerLevel( 2 ) << endl;

  return EXIT_SUCCESS;
}
