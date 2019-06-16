#include <stddef.h>
#include <stdlib.h>
#include "stove.h"

struct stove *new_stove( int burner_count ){
  struct stove *result;
  int i;

  result = malloc( sizeof( *result ) );
  if( !result ) {
    return NULL;
  }

  result->burners = malloc( sizeof( *result->burners ) * burner_count );
  if( !result->burners ) {
    return NULL;
  }

  for( i = 0; i < burner_count; i++ ) {
    result->burner_levels[i] = 0;
  }

  result->burner_count = burner_count;
  result->oven_temp = 0;
}

int get_burner_count( struct stove *s ) {
  return s->burner_count;
}

int get_burner_level( struct stove *s, int burner ) {
  return s->burner_levels[burner];
}

void set_burner_level( struct stove *s, int burner, int level ) {
  s->burner_levels[burner] = level;
}

int get_oven_temp( struct stove *s ) {
  return s->oven_temp;
}

void set_oven_temp( struct stove *s, int new_temp) {
  s->oven_temp = new_temp;
}

void destroy_stove( struct stove *s ) {
  free( s->burners );
  free( s );
}

#endif
