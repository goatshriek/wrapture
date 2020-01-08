#ifndef __CHILDPOINTER_HPP
#define __CHILDPOINTER_HPP

#include <ParentPointer.hpp>

namespace wrapture_test {

  class ChildPointer : public ParentPointer {
  public:


    ChildPointer( struct wrapped_struct *equivalent );
  };

}

#endif
