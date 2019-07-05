# Constants

Most libraries have some constant values that are required or make usage easier.
In C code, this can be a `#define` or some `const` value. Most higher level
languages handle constants in some way or another, and the C code can be
translated to this easily using Wrapture.

Consider the following simple library, which sends a command to a VCR (man,
remember those?) to perform a given action.

```c

#define PLAY 1
#define PAUSE 2
#define FAST_FORWARD 3
#define REWIND 4
#define VOLUME_UP 5
#define VOLUME_DOWN 6

void send_command( struct vcr target_vcr, int command );
```

Describing the class to include these constants is straightforward using the
`constants` field.

```yaml
classes:
  - name: "VCR"
    namespace: "mediacenter"
    equivalent-struct:
      name: "vcr"
      includes:
        - "vcr.h"
    constants:
      - name: "PLAY"
```
