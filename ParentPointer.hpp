#ifndef __PARENTPOINTER_HPP
#define __PARENTPOINTER_HPP

namespace wrapture_test {

  class ParentPointer {
  public:

    struct wrapped_struct *equivalent;

    ParentPointer( struct wrapped_struct *equivalent );
  };

}

#endif
