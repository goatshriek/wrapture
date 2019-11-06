# Overloaded Struct Example

C structs do not have a pattern for inheritance, and as such it is a common
pattern for them to be differentiated from one another using something like a
type code or enumeration. However, in an object oriented language the more
common pattern is to create a parent class and inherit from it.

Wrapture provides a way to distinguish between different types of a struct so
that it will be transparently translated to the correct class. Let's consider a
simple struct that describes an event detected by a security system. Different
events come with different information attached, which should be interpreted
based on the event code provided.

```c
struct event {
  int code;
  void *data;
};
```

We can wrap the struct at a general level in the normal manner:

```yaml
classes:
  - name: "SecurityEvent"
    namespace: "security_system"
    equivalent-struct:
      name: "event"
      includes: "security_system.h"
      members:
        - name: "code"
          type: "int"
        - name: "data"
          type: "void *"
```

Note that we have specified the members so that a default constructor and
destructor are created. This is not a requirement, but will create a quick and
simple way to work with the class for the example.

Next we'll need to break out the different types of events into their own
specialized classes. The code may be any of a number of values depending on what
sort of event is detected. In our example here we'll handle events for a motion
detector, a glass break sensor, and a camera recording. Assuming that there are
well-named `#define`s for these codes, we can create their classes like this:

### Pick up here

```yaml
  - name: "MotionEvent"
    namespace: "security_system"
    parent:
      name: "SecurityEvent"
      includes: "security_system.h"
    equivalent-struct:
      name: "event"
      includes: "security_system.h"
      members:
        - name: "data"
          type: "void *"
      rules:
        - member-name: "code"
          condition: "equals"
          value: "MOTION_DETECTOR_EVENT"
  - name: "GlassBreakEvent"
    namespace: "security_system"
    parent:
      name: "SecurityEvent"
      includes: "security_system.h"
    equivalent-struct:
      name: "event"
      includes: "security_system.h"
      members:
        - name: "data"
          type: "void *"
      rules:
        - member-name: "code"
          condition: "equals"
          value: "GLASS_BREAK_EVENT"
  - name: "CameraEvent"
    namespace: "security_system"
    parent:
      name: "SecurityEvent"
      includes: "security_system.h"
    equivalent-struct:
      name: "event"
      includes: "security_system.h"
      members:
        - name: "data"
          type: "void *"
      rules:
        - member-name: "code"
          condition: "equals"
          value: "CAMERA_EVENT"
```

This will create a class for each of these cases as expected. However, and
perhaps more importantly, it will also create a function in the parent
SecurityEvent class that can create an event based on an `event` struct by
checking the rules. This function will be called `newSecurityEvent` and will
look like this:

```cpp
SecurityEvent newSecurityEvent( struct event *equivalent ) {
  if( equivalent->code == MOTION_DETECTOR_EVENT ) {
    return MotionEvent( equivalent );
  } else if( equivalent->code == GLASS_BREAK_EVENT ) {
    return GlassBreakEvent( equivalent );
  } else if( equivalent->code == CAMERA_EVENT ) {
    return CameraEvent( equivalent );
  } else {
    return SecurityEvent( equivalent );
  }
}
```

Note that the content of this function is taken directly from the `rules` list
that was defined for each of the children of `SecurityEvent`. These rules can
define the conditions to be checked in a variety of ways - for the complete set
of capabilities, see the documentation for the RuleSpec class.

This allows security events to be returned in a way that supports polymorphism
in a natural way, like this:

```cpp
// need to add usage example
```

The full example has a complete implementation of this concept, and can be
compiled and run as follows:

```sh
# generating the wrapper source code
wrapture security_event.yml

# assuming that you're using sh and have g++
g++ -I . -o event_usage_example # add files
./event_usage_example

# output:
# <add output>
```
