#include <cstdlib>
#include <iostream>
#include <Stove.hpp>

using namespace std;
using namespace kitchen;

int main( int argc, char **argv ) {
  Stove my_stove (4);

  cout << "burner count is: " << my_stove.GetBurnerCount() << endl;

  return EXIT_SUCCESS;
}
