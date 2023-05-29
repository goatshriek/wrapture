#!/usr/bin/env python

# SPDX-License-Identifier: Apache-2.0

# Copyright 2023 Joel E. Anderson
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

import mediacenter

living_room = mediacenter.VCR(3)
bedroom = mediacenter.VCR(4)

living_room.SendCommand(mediacenter.VCR::PAUSE_COMMAND)
bedroom.SendCommand(mediacenter.VCR::PLAY_COMMAND)
