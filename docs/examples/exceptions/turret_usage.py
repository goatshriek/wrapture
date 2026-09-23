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

import defense_turret

blaster = defense_turret.Turret()
blaster.aim(-1, 2, 5 )

try:
    for _ in range(15):
        blaster.fire()
    exit('fired 15 shots without jamming!')
except defense_turret.TurretException as e:
    print(e.message())

blaster.reload()

try:
    for i in range(15):
        blaster.aim( 7, 7, i)
        blaster.fire()
except defense_turret.TurretException as e:
    print(e.message())

try:
    blaster.aim( -6, -6, -6)
    exit('aimed at an invalid location without error!')
except defense_turret.TargetingException as e:
    print(e.message())
