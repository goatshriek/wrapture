#include <cstdlib>
#include <iostream>
#include <PlayerStats.hpp>

using namespace std;
using namespace soccer;

int main( int argc, char **argv ) {
  PlayerStats default_player;
  PlayerStats my_player ( 3, 5, 1 );
  PlayerStats their_player (0, 4, 4 );

  cout << "default player's stats:\n  ";
  default_player.Print();

  cout << "my player's stats:\n  ";
  my_player.Print();

  cout << "their player's stats:\n  ";
  their_player.Print();

  return EXIT_SUCCESS;
}
