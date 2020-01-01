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
    namespace: "defense_turret"
    parent:
      name: "std::exception"
      includes: "exception"
    equivalent-struct:
      name: "turret_error"
      includes: "turret_error.h"
    constructors:
      - wrapped-function:
          name: "null_error"
          return:
            type: "equivalent-struct-pointer"
    functions:
      - name: "message"
        virtual: true
        return:
          type: "const char *"
        wrapped-function:
          name: "get_error_message"
          includes: "turret_error.h"
          params:
            - value: "equivalent-struct-pointer"
          return:
            type: "const char *"
```

Note that we have specified that this class will inherit from the standard
exception class, as one would expect. We have also specified the members so
that a default constructor and destructor are created. This allows the class
to be created and thrown like any other Exception class.

The error code may be any of a number of values depending on what sort of
problem is encountered. In our wrapper we need to generate an exceptions for
cases when the turret has jammed, run out of ammunition, or is not able to aim.
Assuming that there are well-named `#define`s for these codes, we can create
their exception classes like this:

```yaml
  - name: "JammedException"
    namespace: "defense_turret"
    type: "pointer"
    parent:
      name: "TurretException"
      includes: "TurretException.hpp"
    equivalent-struct:
      name: "turret_error"
      includes: "turret_error.h"
      rules:
        - member-name: "code"
          condition: "equals"
          value: "JAMMED"
    functions:
      - name: "message"
        # rest of function definition...
  - name: "OutOfAmmoException"
    namespace: "defense_turret"
    type: "pointer"
    parent:
      name: "TurretException"
      includes: "TurretException.hpp"
    equivalent-struct:
      name: "turret_error"
      includes: "turret_error.h"
      rules:
        - member-name: "code"
          condition: "equals"
          value: "OUT_OF_AMMO"
    functions:
      - name: "message"
        # rest of function definition...
  - name: "TargetingException"
    namespace: "defense_turret"
    type: "pointer"
    parent:
      name: "TurretException"
      includes: "TurretException.hpp"
    equivalent-struct:
      name: "turret_error"
      includes: "turret_error.h"
      rules:
        - member-name: "code"
          condition: "equals"
          value: "TARGETING_ERROR"
    functions:
      - name: "message"
        # rest of function definition...
```

Note that we have used the `rules` key in the description of the underlying
struct here in order to have the structs translated to the proper class. If
you want to see more about how that works, check out the overloaded struct
example for a detailed explanation.

Now that we've defined the errors we expect to see, let's define some functions
in a class that check for errors and throw an exception if there is a problem.

```yaml
name: "Turret"
# struct, constructors, and destructor specs...
functions:
  - name: "Aim"
    params:
      - name: "x"
        type: "int"
      - name: "y"
        type: "int"
      - name: "z"
        type: "int"
    wrapped-function:
      name: "aim"
      params:
        - value: "equivalent-struct-pointer"
        - value: "x"
        - value: "y"
        - value: "z"
      return:
        type: "struct turret_error *"
      error-check:
        rules:
          - left-expression: "return-value"
            condition: "not-equals"
            right-expression: "success()"
        error-action:
          name: "throw-exception"
          constructor:
            name: "TargetingException"
            includes: "TargetingException.hpp"
            params:
              - value: "return-value"
```

The `error-check` section of the `Aim` function defines how errors are detected
after the wrapped function is called. The `rules` provided specify the check
to be performed, followed by the action to take in the `error-action` section.

We could catch exceptions thrown by the `Aim` function like this:

```cpp
try {
  blaster.Aim( x, y, z );
} catch( TargetingException &e ) {
  cout << e.message() << endl;
}
```

In the above example, we knew that the wrapped function could only possibly have
a targeting error, so we used the constructor for `TargetingException` in the
call. However, a wrapped function could easily have more than one potential
problem. In cases like this, you can use the overloaded struct function to
create the exception, like this:

```
name: "Fire"
wrapped-function:
  name: "fire"
  params:
    - value: "equivalent-struct-pointer"
  return:
    type: "struct turret_error *"
  error-check:
    rules:
      - left-expression: "return-value"
        condition: "not-equals"
        right-expression: "success()"
    error-action:
      name: "throw-exception"
      constructor:
        name: "TurretException::newTurretException"
        includes: "TurretException.hpp"
        params:
          - value: "return-value"yaml
```

Which would then be used like so:

```cpp
try {
  for( int i = 0; i < 15; i++ ) {
    blaster.Fire();
  }
} catch( TurretException *e ) {
  cout << e->message() << endl;
}
```

The full example has a complete implementation of this concept, and can be
compiled and run as follows:

```sh
# generating the wrapper source code
wrapture turret.yml

# assuming that you're using sh and have g++
g++ -I . \
    turret.c turret_error.c \
    Turret.cpp \
    JammedException.cpp OutOfAmmoException.cpp \
    TargetingException.cpp TurretException.cpp \
    turret_usage.cpp \
    -o turret_usage_example
./turret_usage_example

# generates the following output:
# aimed at (-1, 2, 5)
# fired at (-1, 2, 5)
# fired at (-1, 2, 5)
# fired at (-1, 2, 5)
# fired at (-1, 2, 5)
# ah crap, the turret jammed!
# reloaded!
# aimed at (7, 7, 0)
# fired at (7, 7, 0)
# aimed at (7, 7, 1)
# fired at (7, 7, 1)
# aimed at (7, 7, 2)
# fired at (7, 7, 2)
# aimed at (7, 7, 3)
# fired at (7, 7, 3)
# aimed at (7, 7, 4)
# fired at (7, 7, 4)
# aimed at (7, 7, 5)
# fired at (7, 7, 5)
# aimed at (7, 7, 6)
# fired at (7, 7, 6)
# aimed at (7, 7, 7)
# fired at (7, 7, 7)
# aimed at (7, 7, 8)
# fired at (7, 7, 8)
# aimed at (7, 7, 9)
# fired at (7, 7, 9)
# aimed at (7, 7, 10)
# the turret is out of ammo, reload!
# I can't aim at the fourth quadrant...
```

