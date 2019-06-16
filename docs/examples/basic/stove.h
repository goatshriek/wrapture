#ifndef STOVE_H
#define STOVE_H

struct stove {
  int burner_count;
  int *burner_levels;
  int oven_temp;
};

struct stove *new_stove( int burner_count );
int get_burner_count( struct stove *s );
int get_burner_level( struct stove *s, int burner );
void set_burner_level( struct stove *s, int burner, int level );
int get_oven_temp( struct stove *s );
void set_oven_temp( struct stove *s, int new_temp);
void destroy_stove( struct stove *s );

#endif
