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

#include <cstdlib>
#include <iostream>
#include <Turret.hpp>
#include <TurretException.hpp>
#include <TargetingException.hpp>
#include <OutOfAmmoException.hpp>
#include <JammedException.hpp>

using namespace std;
using namespace defense_turret;

int main( int argc, char **argv ) {
  Turret blaster;

  blaster.Aim( -1, 2, 5 );

  try {
    for( int i = 0; i < 15; i++ ) {
      blaster.Fire();
    }
  } catch( TurretException *e ) {
    cout << e->message() << endl;
  }

  blaster.Reload();

  try {
    for( int i = 0; i < 15; i++ ) {
      blaster.Aim( 7, 7, i );
      blaster.Fire();
    }
  } catch( TurretException *e ) {
    cout << e->message() << endl;
  }

  try {
    blaster.Aim( -6, -6, 6 );
  } catch( TargetingException &e ) {
    cout << e.message() << endl;
  }

  return EXIT_SUCCESS;
}
