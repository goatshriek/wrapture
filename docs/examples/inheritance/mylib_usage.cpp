// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2024-2026 Joel E. Anderson
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
#include <Book.hpp>
#include <Item.hpp>

using namespace std;
using namespace library;

static const int NOT_BAD_PAGE_COUNT = 500;
static const int TOO_MANY_PAGE_COUNT = 1000;

int main( int argc, char **argv ) {
  Item movie( "Space Mutiny" );
  Book harry_potter( "Harry Potter and the Chamber of Commerce",
                     false,
                     NOT_BAD_PAGE_COUNT );
  Item tablet( "Tax Educator 2002" );
  Book lord_of_the_rings( "The Two Showers", false, TOO_MANY_PAGE_COUNT );

  int pc =  harry_potter.GetPageCount();
  cout << "Harry Potter has " << pc << " pages, not too bad." << endl;
  if( pc != NOT_BAD_PAGE_COUNT ){
    cerr << "Harry Potter didn't have the right page count!" << endl;
    return EXIT_FAILURE;
  }
  harry_potter.CheckOut();

  movie.CheckOut();
  tablet.CheckOut();

  pc = lord_of_the_rings.GetPageCount();
  cout << "Lord of the Rings has " << pc << " pages, too much!" << endl;
  if( pc != TOO_MANY_PAGE_COUNT ){
    cerr << "Lord of the Rings didn't have the right page count!" << endl;
    return EXIT_FAILURE;
  }

  return EXIT_SUCCESS;
}
