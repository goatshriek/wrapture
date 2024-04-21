# Inheritance with Wrapture
Of course there will come a time when you want to create a class that is a
child of some other class. Wrapture makes this straightforward: all
that you need to do is specify the name of the class you wish to inherit from,
and of course any headers that must be included to make this valid.

A common example of this scenario is wrapping some custom error handling code in
an exception in the target language. Let's consider a simple example where we
want to create an exception wrapper for an error code in our library.

```c
struct mylib_error {
  int code;
  const char *message;
};
```

Wrapping this simple error struct is easy: we simply add a `parent` field
specifying the class to inherit from.

```yaml
classes:
  - name: "MylibError"
    namespace: "mylib"
    equivalent-struct:
      name: "mylib_error"
    parent:
      name: "std::exception"
      includes: "exception"
```

We will also add a constructor for the class so that it can be thrown without
any additional arguments:

```yaml
    constructors:
      - wrapped-function:
          name: "raise_mylib_error"
          includes: "mylib.h"
          return:
            type: "equivalent-struct-pointer"
```

The result of this spec is a class that inherits from the standard library's
exception class and is also a wrapping of the wrapped library's error struct.
You can then throw this exception like you would any native exception:

```cpp
void i_will_fail( void ) {
  throw MylibError();
}
```

If you want to run this example, all that remains after using wrapture to
generate the sources is to compile them and run the `error_usage` program to see
the output:

```sh
# assuming that you're using sh and have g++
g++ -I . mylib.c MylibError.cpp error_usage.cpp -o error_usage_example
./error_usage_example
```
