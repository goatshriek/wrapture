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

#ifndef __MYLIB_H
#define __MYLIB_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/** An item that can be checkout out from my library. */
struct mylib_item {
  /** The name of the item. */
  const char *name;
  /** Whether or not the item is checked out. */
  bool checked_out;
  /** The number of pages in a book. */
  int page_count;
};

/** Checks out an item. */
void check_out_item( struct mylib_item *item );

/** Gets the number of pages for a book. */
int get_page_count( struct mylib_item *item );

#ifdef __cplusplus
}
#endif

#endif
