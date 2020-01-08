#include <ParentPointer.hpp>

namespace wrapture_test {
  ParentPointer::ParentPointer( struct wrapped_struct *equivalent ) {
    this->equivalent = equivalent;
  }

}
