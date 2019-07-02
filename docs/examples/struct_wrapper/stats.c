#include <stdio.h>
#include <stats.h>

void print_player_stats( struct player_stats *stats ) {
  printf( "this player has scored %d goals and has earned %d yellow cards "
          "and %d red cards\n",
          stats->goals_scored,
          stats->yellow_cards,
          stats->red_cards );
}
