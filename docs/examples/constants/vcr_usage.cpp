#include <cstdlib>
#include <VCR.hpp>

using namespace mediacenter;

int main(int argc, char **argv) {
  VCR living_room ( 3 );
  VCR bedroom ( 4 );

  living_room.SendCommand( VCR::PAUSE_COMMAND );
  bedroom.SendCommand( VCR::PLAY_COMMAND );

  return EXIT_SUCCESS;
}
