#include <fridge.h>
#include <stddef.h>
#include <stdlib.h>

struct fridge *
new_fridge( int temperature ){
  struct fridge *fridge;

  fridge = malloc( sizeof( *fridge ) );
  if( !fridge ){
    return NULL;
  }

  fridge->temp = 42;
  fridge->ice = NULL;
  fridge->filter = NULL;
  fridge->freezer = NULL;
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
