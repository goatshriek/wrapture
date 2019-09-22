#ifndef __MYLIB_H
#define __MYLIB_H

struct mylib_error {
  int code;
  const char *message;
};

struct mylib_error *
raise_mylib_error( void );

#endif
