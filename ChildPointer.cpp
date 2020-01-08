#include <ChildPointer.hpp>

namespace wrapture_test {
  ChildPointer::ChildPointer( struct wrapped_struct *equivalent ) : ParentPointer( equivalent ) {
    this->equivalent = equivalent;
  }

}
