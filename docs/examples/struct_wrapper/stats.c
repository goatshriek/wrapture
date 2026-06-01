// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2019-2026 Joel E. Anderson
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

#include <stdio.h>
#include <stats.h>


int get_goals_scored( const struct player_stats *stats ) {
  return stats->goals_scored;
}

int get_yellow_cards( const struct player_stats *stats ) {
  return stats->yellow_cards;
}

int get_red_cards( const struct player_stats *stats ) {
  return stats->red_cards;
}

void
print_player_stats( struct player_stats *stats ) {
  printf( "player scored %d goals, earned %d yellow cards, and %d red cards\n",
          stats->goals_scored,
          stats->yellow_cards,
          stats->red_cards );
}
