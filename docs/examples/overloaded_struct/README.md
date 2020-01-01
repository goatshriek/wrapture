# Overloaded Struct Example

C structs do not have a pattern for inheritance, and as such it is a common
pattern for them to be differentiated from one another using something like a
type code or enumeration. However, in an object oriented language the more
common pattern is to create a parent class and inherit from it. Programs can
then use features like runtime polymorphism to cleanly treat each child class
in the appropriate way.

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
    constructors:
      # constructors...
    destructor:
      # destructor...
```

So far there is nothing special about this class definition. However, there is
a static function that we want to define which will return one of the different
types of events this system defines. We will define this function as most
others, with one extra annotation on the return type:

```yaml
    functions:
      - name: "NextEvent"
        static: true
        return:
          type: "SecurityEvent *"
          overloaded: true
        wrapped-function:
          name: "get_next_event"
          includes: "security_system.h"
```

The `overloaded` key tells Wrapture that this return type should be converted
to a more specific class wrapping when the function is called. Any function that
needs to make use of an overloaded function needs this annotation on the return
type.

Next, we'll need to break out the different types of events into their own
specialized classes. The code may be any of a number of values depending on what
sort of event is detected. In our example here we'll handle events for a motion
detector, a glass break sensor, and a camera recording. Assuming that there are
well-named `#define`s for these codes, we can create their classes like this:

```yaml
  - name: "CameraEvent"
    namespace: "security_system"
    parent:
      name: "SecurityEvent"
      includes: "SecurityEvent.hpp"
    equivalent-struct:
      name: "event"
      includes: "security_system.h"
      rules:
        - member-name: "code"
          condition: "equals"
          value: "CAMERA_EVENT"
    constructors:
      # constructors...
    functions:
      # functions...
  - name: "GlassBreakEvent"
    namespace: "security_system"
    parent:
      name: "SecurityEvent"
      includes: "SecurityEvent.hpp"
    equivalent-struct:
      name: "event"
      includes: "security_system.h"
      rules:
        - member-name: "code"
          condition: "equals"
          value: "GLASS_BREAK_EVENT"
    constructors:
      # constructors...
    functions:
      # functions...
  - name: "MotionEvent"
    namespace: "security_system"
    parent:
      name: "SecurityEvent"
      includes: "SecurityEvent.hpp"
    equivalent-struct:
      name: "event"
      includes: "security_system.h"
      rules:
        - member-name: "code"
          condition: "equals"
          value: "MOTION_EVENT"
    constructors:
      # constructors...
    functions:
      # functions...
```

This will create a class for each of these cases as expected. However, and
perhaps more importantly, it will also create a function in the parent
SecurityEvent class that can create an event based on an `event` struct by
checking the rules. This function will be called `newSecurityEvent` and will
look like this:

```cpp
SecurityEvent *SecurityEvent::newSecurityEvent( struct event *equivalent ) {
  if( equivalent->code == CAMERA_EVENT ) {
    return new CameraEvent( equivalent );
  } else if( equivalent->code == GLASS_BREAK_EVENT ) {
    return new GlassBreakEvent( equivalent );
  } else if( equivalent->code == MOTION_EVENT ) {
    return new MotionEvent( equivalent );
  } else {
    return new SecurityEvent( equivalent );
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
SecurityEvent *ev = SecurityEvent::NextEvent();
ev->Print(); // runs the Print function for the derived class
```

The full example has a complete implementation of this concept, and can be
compiled and run as follows:

```sh
# generating the wrapper source code
wrapture security_event.yml

# assuming that you're using sh and have g++
g++ -I . \
    security_system.c CameraEvent.cpp GlassBreakEvent.cpp MotionEvent.cpp \
    SecurityEvent.cpp event_usage.cpp \
    -o event_usage_example
./event_usage_example

# output:
# motion event: watch out for snakes!
# glass break event: level 3
# camera event: is that bigfoot?
# motion event: watch out for snakes!
# glass break event: level 4
```

