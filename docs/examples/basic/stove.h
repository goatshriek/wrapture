#ifndef __STOVE_H
#define __STOVE_H

#  ifdef __cplusplus
extern "C" {
#  endif

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

int is_model_supported( int model );

#  ifdef __cplusplus
}
#  endif

#endif
