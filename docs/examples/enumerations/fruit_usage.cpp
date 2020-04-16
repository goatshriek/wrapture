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
#include <seedless_desire.h>
#include <citrus_mangiamo.h>
#include <Fruit.hpp>

using namespace std;

int
main( int argc, char **argv ){
  // comparisons between types can be done using the underlying integers
  // note that static cast is needed to compare with an integer 
  if( static_cast<int>( Fruit::watermelon ) == DESIRE_WATERMELON ) {
    cout << "Fruit::watermelon is equal to DESIRE_WATERMELON" << endl;
  }

  // instead of casting, you could also go the other way and create a Fruit
  // from the original value instead
  if( Fruit::lime == Fruit(MANGIAMO_LIME) ) {
    cout << "Fruit::lime is equal to MANGIAMO_LIME" << endl;
  }

  return EXIT_SUCCESS;
}
