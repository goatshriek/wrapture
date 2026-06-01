#!/usr/bin/env python

# SPDX-License-Identifier: Apache-2.0

# Copyright 2024-2026 Joel E. Anderson
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from library import Book, Item

NOT_BAD_PAGE_COUNT = 500;
TOO_MANY_PAGE_COUNT = 1000;

movie = Item("Space Mutiny")
harry_potter = Book("Harry Potter and the Chamber of Commerce",
                    False,
                    NOT_BAD_PAGE_COUNT)
tablet = Item("Tax Educator 2002")
lord_of_the_rings = Book("The Two Showers", False, TOO_MANY_PAGE_COUNT)

pc =  harry_potter.GetPageCount()
print(f"Harry Potter has {pc} pages, not too bad.")
if pc != NOT_BAD_PAGE_COUNT:
    exit("Harry Potter didn't have the right page count!")
harry_potter.CheckOut()

movie.CheckOut()
tablet.CheckOut()

pc = lord_of_the_rings.GetPageCount()
print(f"Lord of the Rings has {pc} pages, too much!")
if pc != TOO_MANY_PAGE_COUNT:
    exit("Lord of the Rings didn't have the right page count!")
