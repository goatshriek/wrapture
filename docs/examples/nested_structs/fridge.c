#include <fridge.h>
#include <stddef.h>
#include <stdlib.h>

struct fridge *
new_fridge( int temperature ){
  struct fridge *fridge;

  fridge = ( struct fridge * ) malloc( sizeof( *fridge ) );
  if( !fridge ){
    return NULL;
  }

  fridge->temp = 42;
  fridge->ice = NULL;
  fridge->filter = NULL;
  fridge->freezer = NULL;

  return fridge;
}

struct ice_maker *
new_ice_maker( int size, int can_crush_ice ){
  struct ice_maker *maker;

  maker = ( struct ice_maker * ) malloc( sizeof( *maker ) );
  if( !maker ){
    return NULL;
  }

  maker->size = size;
  maker->can_crush_ice = can_crush_ice;

  return maker;
}

struct water_filter *
new_water_filter( int purity_level ){
  struct water_filter *filter;

  filter = ( struct water_filter * ) malloc( sizeof( *filter ) );
  if( !filter ){
    return NULL;
  }

  filter->purity_level = purity_level;

  return filter;
}

struct freezer *
new_freezer( int minimum_temp, int set_temp ){
  struct freezer *freezer;

  freezer = ( struct freezer * ) malloc( sizeof( *freezer ) );
  if( !freezer ){
    return NULL;
  }

  freezer->minimum_temp = minimum_temp;
  freezer->set_temp = set_temp;

  return freezer;
}

void
add_ice_maker_to_fridge( struct fridge *fridge, struct ice_maker *maker ){
  if( !fridge ){
    return;
  }

  if( fridge->ice ){
    free( fridge->ice );
  }

  fridge->ice = maker;
}

void
add_water_filter_to_fridge( struct fridge *fridge,
                            struct water_filter *filter ){
  if( !fridge ){
    return;
  }

  if( fridge->filter ){
    free( fridge->filter );
  }

  fridge->filter = filter;
}

void
add_freezer_to_fridge( struct fridge *fridge, struct freezer *freezer ){
  if( !fridge ){
    return;
  }

  if( fridge->freezer ){
    free( fridge->freezer );
  }

  fridge->freezer = freezer;
}
