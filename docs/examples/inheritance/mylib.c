#include <mylib.h>
#include <stddef.h>
#include <stdlib.h>

struct mylib_error *
raise_mylib_error( void ) {
  struct mylib_error *err;

  err = ( struct mylib_error * ) malloc( sizeof( *err ) );
  if( !err ) {
    return NULL;
  }

  err->code = 3;
  err->message = "ya done messed up, A-A-Ron!!!";

  return err;
}
