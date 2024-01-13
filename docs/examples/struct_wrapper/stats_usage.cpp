/* SPDX-License-Identifier: Apache-2.0 */

/*
 * Copyright 2024 Joel E. Anderson
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
#include <PlayerStats.hpp>

using namespace std;
using namespace soccer;

int main( int argc, char **argv ) {
  PlayerStats default_player;
  PlayerStats my_player ( 3, 5, 1 );
  PlayerStats their_player (0, 4, 4 );

  cout << "default player's stats:\n  ";
  default_player.Print();

  cout << "my player's stats:\n  ";
  my_player.Print();

  cout << "their player's stats:\n  ";
  their_player.Print();

  return EXIT_SUCCESS;
}
