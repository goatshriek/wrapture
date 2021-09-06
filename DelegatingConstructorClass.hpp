#ifndef DELEGATINGCONSTRUCTORCLASS_HPP
#define DELEGATINGCONSTRUCTORCLASS_HPP

#include <class_include.h>
#include <folder/include_file_1.h>

namespace wrapture_test {

  class DelegatingConstructorClass {
  public:
    DelegatingConstructorClass( void );
    DelegatingConstructorClass( int id );
    DelegatingConstructorClass( struct basic_struct *equivalent );

    struct basic_struct *equivalent;
  };

}

#endif /* DELEGATINGCONSTRUCTORCLASS_HPP */
