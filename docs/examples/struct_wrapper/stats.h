#ifndef __STATS_H
#define __STATS_H

struct player_stats {
  int goals_scored;
  int yellow_cards;
  int red_cards;
};

void print_player_stats( struct player_stats *stats );

#endif
