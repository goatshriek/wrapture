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
#include <VCR.hpp>

using namespace mediacenter;

int main(int argc, char **argv) {
  VCR living_room ( 3 );
  VCR bedroom ( 4 );

  living_room.SendCommand( VCR::PAUSE_COMMAND );
  bedroom.SendCommand( VCR::PLAY_COMMAND );

  return EXIT_SUCCESS;
}
