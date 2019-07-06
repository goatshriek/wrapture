#include <cstdlib>
#include <iostream>
#include <Stove.hpp>

using namespace std;
using namespace kitchen;

int main( int argc, char **argv ) {
  if( Stove::IsModelSupported( 4 ) ) {
    cout << "model 4 stoves are supported" << endl;
  }

  Stove my_stove (4);

  cout << "burner count is: " << my_stove.GetBurnerCount() << endl;

  my_stove.SetOvenTemp( 350 );
  cout << "current oven temp is: " << my_stove.GetOvenTemp() << endl;

  my_stove.SetBurnerLevel( 2, 9 );
  cout << "burner 2 level is: " << my_stove.GetBurnerLevel( 2 ) << endl;

  return EXIT_SUCCESS;
}
