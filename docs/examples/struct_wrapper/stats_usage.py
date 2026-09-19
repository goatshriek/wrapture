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

import soccer

default_player = soccer.PlayerStats()
print("default player's stats:")
default_player.print()
if default_player.get_goals_scored() != 0:
    exit("the default player had goals scored!")

my_player = soccer.PlayerStats(3, 5, 1)
print("\nmy player's stats:")
my_player.print()
if my_player.get_yellow_cards() != 5:
    exit("wait, my player has way more yellow cards than that!")

their_player = soccer.PlayerStats(0, 4, 4)
print("\ntheir player's stats:")
their_player.print()
if their_player.get_red_cards() != 4:
    exit("their player has more red cards than that!")
