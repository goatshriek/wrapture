#include <stdio.h>
#include <vcr.h>

void
send_command( struct vcr *target_vcr, int command ) {
  printf( "sending command %d to vcr on channel %d\n",
          command,
          target_vcr->channel );
}
