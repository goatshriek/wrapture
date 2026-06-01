// SPDX-License-Identifier: Apache-2.0

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
#include <Freezer.hpp>
#include <Fridge.hpp>
#include <IceMaker.hpp>
#include <iostream>
#include <WaterFilter.hpp>

using namespace kitchen;
using namespace std;

int main( int argc, char **argv ){
    Fridge kitchen_fridge( 34 );
    WaterFilter filter( 10 );
    IceMaker ice_maker( 10, 1 );
    Freezer freezer( -10, 4 );

    kitchen_fridge.AddFreezer( freezer );
    if( kitchen_fridge.GetFreezerMinimumTemp() != -10 ){
        cerr << "the freezer minimum temperature was not correct!" << endl;
        return EXIT_FAILURE;
    }

    kitchen_fridge.AddIceMaker( ice_maker );
    kitchen_fridge.AddWaterFilter( filter );

    kitchen_fridge.Print();
}