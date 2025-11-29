/* SPDX-License-Identifier: Apache-2.0 */

/*
 * Copyright 2025 Joel E. Anderson
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

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Adds two numbers and checks for overflow, returning the min/max value if
 * overflow occurs.
 *
 * @param n1 n2 The two numbers to add.
 *
 * @return The result of adding the numbers, or INT_MIN if underflow occurs, or
 * INT_MAX if overflow occurs.
 */
int cmakeclib_add( int n1, int n2 );

#ifdef __cplusplus
} /* extern "C" */
#endif