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
#include <Vcr.hpp>

using namespace mediacenter;
using namespace std;

int main(int argc, char **argv) {
  Vcr living_room ( 3 );
  Vcr bedroom ( 4 );
  int sent;

  sent = living_room.SendCommand( Vcr::PAUSE_COMMAND );
  if( sent != Vcr::PAUSE_COMMAND ){
    cerr << "the pause command wasn't sent!" << endl;
    return EXIT_FAILURE;
  }

  sent = bedroom.SendCommand( Vcr::PLAY_COMMAND );
  if( sent != Vcr::PLAY_COMMAND ){
    cerr << "the play command wasn't sent!" << endl;
    return EXIT_FAILURE;
  }

  return EXIT_SUCCESS;
}
