#ifndef __VCR_H
#define __VCR_H

#define PLAY 1
#define PAUSE 2
#define FAST_FORWARD 3
#define REWIND 4
#define VOLUME_UP 5
#define VOLUME_DOWN 6

struct vcr {
  int channel;
};

void send_command( struct vcr *target_vcr, int command );

#endif
