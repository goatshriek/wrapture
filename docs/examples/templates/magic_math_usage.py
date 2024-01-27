#!/usr/bin/env python

# SPDX-License-Identifier: Apache-2.0

# Copyright 2024 Joel E. Anderson
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

import magic_stuff

print('listing primes from 0 to 100:')

for i in range(100):
    if magic_stuff.MagicMath.isPrime(i):
        print(i)
