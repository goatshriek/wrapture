# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2021-2023 Joel E. Anderson
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
#++

module Wrapture
  # Methods useful for named items such as specs.
  #
  # This module expects that +name+ gives a CamelCase name. Other
  # transformations are based on this assumption. Names with multiple capital
  # letters in sequence, such as 'AARConnection', contain an initialism and are
  # interpreted as such. So for example, the result of +snake_case_name+ of the
  # previous example would be 'aar_connection'.
  module Named
    # The name of this item in snake case.
    def snake_case_name
      name.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
          .gsub(/([a-z\d])([A-Z])/, '\1_\2')
          .downcase
    end
  end
end
