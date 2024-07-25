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

from kitchen import Freezer, Fridge, IceMaker, WaterFilter

kitchen_fridge = Fridge( 34 )
filter = WaterFilter( 10 )
ice_maker = IceMaker( 10, 1 )
freezer = Freezer( -10, 4 )

kitchen_fridge.AddFreezer( freezer )
kitchen_fridge.AddIceMaker( ice_maker )
kitchen_fridge.AddWaterFilter( filter )

kitchen_fridge.Print()
