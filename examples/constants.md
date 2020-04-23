# Constants

Most libraries have some constant values that are required or make usage easier.
In C code, this can be a `#define` or some `const` value. Most higher level
languages handle constants in some way or another, and Wrapture cand translate
the C code to fit.

Consider the following simple library, which sends a command to a VCR (man,
remember those?) to perform a given action.

```c
#define PLAY 1
#define PAUSE 2
#define FAST_FORWARD 3
#define REWIND 4
#define VOLUME_UP 5
#define VOLUME_DOWN 6

void send_command( struct vcr *target_vcr, int command );
```

Describing the class to include these constants is straightforward using the
`constants` list, as shown below. The function description is left off, as there
is nothing special about it (you can check the .yml file in this example to see
the full specification)..

```yaml
classes:
  - name: "VCR"
    namespace: "mediacenter"
    equivalent-struct:
      name: "vcr"
      includes:
        - "vcr.h"
    constants:
      - name: "PLAY_COMMAND"
        type: "int"
        value: "PLAY"
        includes:
          - "vcr.h"
      - name: "PAUSE_COMMAND"
        type: "int"
        value: "PAUSE"
      - name: "FAST_FORWARD_COMMAND"
        type: "int"
        value: "FAST_FORWARD"
      - name: "REWIND_COMMAND"
        type: "int"
        value: "REWIND"
      - name: "VOLUME_UP_COMMAND"
        type: "int"
        value: "VOLUME_UP"
      - name: "VOLUME_DOWN_COMMAND"
        type: "int"
        value: "VOLUME_DOWN"
```

Constants are given a name, type, and value which describe how they are defined
in the wrapped language. The descriptions above will result in the following
constant definitions inside of the C++ class:

```cpp
namespace mediacenter {

  class VCR {
  public:

    static const int PLAY_COMMAND;
    static const int PAUSE_COMMAND;
    static const int FAST_FORWARD_COMMAND;
    static const int REWIND_COMMAND;
    static const int VOLUME_UP_COMMAND;
    static const int VOLUME_DOWN_COMMAND;

    // rest of class definition
  };
}
```

If you want to run this example, all that remains after using wrapture to
generate the sources is to compile the various sources and run the `vcr_usage`
program to see the output:

```sh
# assuming that you're using sh and have g++
g++ -I . vcr.c VCR.cpp vcr_usage.cpp -o vcr_usage_example
./vcr_usage_example
```
