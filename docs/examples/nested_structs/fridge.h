#ifndef __FRIDGE_H
#define __FRIDGE_H

struct ice_maker {
  int size;
  int can_crush_ice; // boolean value
};

struct water_filter {
  int purity_level;
};

struct freezer {
  int minimum_temp;
  int set_temp;
};

struct fridge {
  int temp;
  struct ice_maker *ice;
  struct water_filter *filter;
  struct freezer *freezer;
};

struct fridge *
new_fridge( int temperature );

struct ice_maker *
new_ice_maker( int size, int can_crush_ice );

struct water_filter *
new_water_filter( int purity_level );

struct freezer *
new_freezer( int minimum_temp, int set_temp );

void
add_ice_maker_to_fridge( struct fridge *fridge, struct ice_maker *maker );

void
add_water_filter_to_fridge( struct fridge *fridge,
                            struct water_filter *filter );

void
add_freezer_to_fridge( struct fridge *fridge, struct freezer *freezer );

#endif
