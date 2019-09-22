#include <cstdlib>
#include <iostream>
#include <MylibError.hpp>

using namespace std;
using namespace mylib;

void i_will_fail( void ) {
  throw MylibError();
}

int main( int argc, char **argv ) {
  try {
    i_will_fail();
  } catch( MylibError err ) {
    cout << "caught a MylibError with message: " << err.equivalent->message << endl;
  }

  return EXIT_SUCCESS;
}
