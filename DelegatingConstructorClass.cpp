#include <DelegatingConstructorClass.hpp>
#include <class_include.h>

namespace wrapture_test {

  DelegatingConstructorClass::DelegatingConstructorClass( void ) {
  
    this->equivalent = default_constructor(  );
    
  }

  DelegatingConstructorClass::DelegatingConstructorClass( int id ) {
  
    this->equivalent = underlying_constructor( id );
    
  }

  DelegatingConstructorClass::DelegatingConstructorClass( struct basic_struct *equivalent ) {
  
    this->equivalent = equivalent;
    
  }

}
