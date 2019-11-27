# Overloaded Struct Example

Error handling in C is typically handled by simple methods like checking a
return code or checking some other global variable. However, most higher level
languages have better way of handling errors, typically by throwing exceptions.


C structs do not have a pattern for inheritance, and as such it is a common
pattern for them to be differentiated from one another using something like a
type code or enumeration. However, in an object oriented language the more
common pattern is to create a parent class and inherit from it. This is most
obvious in the exception classes of most languages, where different kinds of
errors are different classes which are children of the main exception or error
classes.

Wrapture provides a way to distinguish between different types of a struct so
that it will be translated to the correct class. This example demonstrates the
concept using a common exception pattern, but it can be used in other
ways as well.

Let's consider a simple error struct that consists of an integer error code and
a string message describing the problem. This error struct is used by a library
that provides access to an automated foam dart turret.

```c
struct turret_error {
  int code;
  const char *message;
};
```

We can wrap the struct at a general level in the normal manner:

```yaml
classes:
  - name: "TurretException"
    namespace: "turret"
    parent:
      name: "std::exception"
      includes: "exception"
    equivalent-struct:
      name: "turret_error"
      includes: "turret_error.h"
      members:
        - name: "code"
          type: "int"
        - name: "message"
          type: "const char *"
```

Note that we have specified that this class will inherit from the standard
exception class, as one would expect. We have also specified the members so
that a default constructor and destructor are created. This allows the class
to be created and thrown like any other Exception class.

But if we'd like users of our wrapper to catch different exceptions in a more
natural way, we'll need to break out the different types of errors into their
own specialized classes.

The error code may be any of a number of values depending on what sort of
problem is encountered. In our wrapper we need to generate an exceptions for
cases when the turret has jammed, run out of ammunition, or is not able to aim.
Assuming that there are well-named `#define`s for these codes, we can create
their exception classes like this:

```yaml
  - name: "TargetingException"
    namespace: "turret"
    parent:
      name: "TurretException"
      includes: "TurretException.hpp"
    equivalent-struct:
      name: "turret_error"
      includes: "turret_error.h"
      members:
        - name: "code"
          type: "int"
        - name: "message"
          type: "const char *"
      rules:
        - member-name: "code"
          condition: "equals"
          value: "TARGETING_ERROR"
  - name: "OutOfAmmoException"
    namespace: "turret"
    parent:
      name: "TurretException"
      includes: "TurretException.hpp"
    equivalent-struct:
      name: "turret_error"
      includes: "turret_error.h"
      members:
        - name: "code"
          type: "int"
        - name: "message"
          type: "const char *"
      rules:
        - member-name: "code"
          condition: "equals"
          value: "OUT_OF_AMMO"
  - name: "JammedException"
    namespace: "turret"
    parent:
      name: "TurretException"
      includes: "TurretException.hpp"
    equivalent-struct:
      name: "turret_error"
      includes: "turret_error.h"
      members:
        - name: "code"
          type: "int"
        - name: "message"
          type: "const char *"
      rules:
        - member-name: "code"
          condition: "equals"
          value: "JAMMED"
```

Note that we have used the `rules` key in the description of the underlying
struct here in order to have the structs translated to the proper class. If
you want to see more about how that works, check out the overloaded struct
example for a detailed explanation.

Now that we've defined the errors we expect to see, let's define some functions
that checks for errors and throw an exception if there is a problem.

```yaml

```


```cpp
// need to add usage example
```

The full example has a complete implementation of this concept, and can be
compiled and run as follows:

```sh
# generating the wrapper source code
wrapture turret.yml

# assuming that you're using sh and have g++
g++ -I . -o turret_usage_example # add files
./turret_usage_example

# generates the following output:
# <add output>
```
