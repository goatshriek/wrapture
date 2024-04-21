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
#include <iostream>
#include <Book.hpp>
#include <Item.hpp>

using namespace std;
using namespace library;

int main( int argc, char **argv ) {
  Item movie("Space Mutiny");
  Book harry_potter("Harry Potter and the Chamber of Commerce", false, 500);
  Item tablet("Tax Educator 2002");
  Book lord_of_the_rings("The Two Showers", false, 1000);

  movie.CheckOut();
  int pc =  harry_potter.GetPageCount();
  cout << "Harry Potter has " << pc << " pages, not too bad." << endl;
  harry_potter.CheckOut();
  tablet.CheckOut();
  pc = lord_of_the_rings.GetPageCount();
  cout << "Lord of the Rings has " << pc << " pages, too much!" << endl;

  return EXIT_SUCCESS;
}
