# Basic Wrapture Example

The simplest use of Wrapture is to wrap C code that's already been built in
a class-like structure. Consider the following C code, which details a simple
struct and associated functions that describe a stove:

```c
struct stove {
  int burner_count;
  int *burner_levels;
  int oven_temp;
};

struct stove *new_stove( int burner_count );
int get_burner_count( struct stove *s );
int get_burner_level( struct stove *s, int burner );
void set_burner_level( struct stove *s, int burner, int level );
int get_oven_temp( struct stove *s );
void set_oven_temp( struct stove *s, int new_temp);
void destroy_stove( struct stove s );

int is_model_supported( int model );
```

We would like to create a Stove class that mimics the functionality of this C
code in our output language (C++). First, we add the class to the classes list
with a few basic attributes:

```yaml
classes:
  - name: "Stove"
    namespace: "kitchen"
    includes:
      - "stove.h"
```

We describe the underlying struct by simply giving its name:

```yaml
    equivalent-struct:
      name: "stove"
```

For most elements within Wrapture, you may also specify an `includes` list of
header files necessary for the element, in this case the struct. Doing this for
each element will result in more efficient header lists and compilation times in
some cases, but this can be tedious. Specifying this at the class level, as we
do here, is easier and less verbose.

Next, we describe our only constructor function. We'll do this by specifying
its name, parameters, and return type:

```yaml
    constructors:
      - wrapped-function:
          name: "new_stove"
          params:
            - name: "burner_count"
              type: "int"
          return:
            type: "equivalent-struct-pointer"
```

Note the use of the special return type of `equivalent-struct-pointer`, which
tells Wrapture that the output of the function is a pointer to a struct that
is the underlying type.

Next, we describe the destructor function in a similar way:

```yaml
    destructor:
      wrapped-function:
        name: "destroy_stove"
        params:
          - name: "equivalent-struct-pointer"
```

Using `equivalent-struct-pointer` as a parameter passes the pointer created
by the constructor into the function.

Finally, we just need to describe the four functions that our class will have
for working with the stove. Let's start with the two simplest:

```yaml
    functions:
      - name: "GetBurnerCount"
        return:
          type: "int"
        wrapped-function:
          name: "get_burner_count"
          params:
            - name: "equivalent-struct-pointer"
      - name: "GetOvenTemp"
        return:
          type: "int"
        wrapped-function:
          name: "get_oven_temp"
          params:
            - name: "equivalent-struct-pointer"
```

Note that the generated functions will not have any parameters, even though the
underlying C functions do. This is because we have passed the internal struct
to the native function, hiding it from the output language interface.

The `set_oven_temp` function shows how we can specify a parameter if one is
needed:

```yaml
      - name: "SetOvenTemp"
        params:
          - name: "new_temp"
            type: "int"
        wrapped-function:
          name: "set_oven_temp"
          params:
            - name: "equivalent-struct-pointer"
            - name: "new_temp"
```

Because the name of the second parameter in the native function matches one of
those in the output language, it will be set directly to whatever is passed into
the output language interface. Also, note that the name of this parameter does
not need to match the name used in the function declaration.

We can define the remaining two functions in the same way:

```yaml
      - name: "GetBurnerLevel"
        params:
          - name: "burner_index"
            type: "int"
        return:
          type: "int"
        wrapped-function:
          name: "get_burner_level"
          params:
            - name: "equivalent-struct-pointer"
            - name: "burner_index"
      - name: "SetBurnerLevel"
        params:
          - name: "burner_index"
            type: "int"
          - name: "new_level"
            type: "int"
        wrapped-function:
          name: "set_burner_level"
          params:
            - name: "equivalent-struct-pointer"
            - name: "burner_index"
            - name: "new_level"
```

Static functions are defined in the same manner, but with one additional field
named `static` set to true.

```yaml
      - name: "IsModelSupported"
        static: true
        return:
          type: "bool"
        params:
          - name: "model"
            type: "int"
        wrapped-function:
          name: "is_model_supported"
          params:
            - name: "model"
```

This specification will generate a Stove class with all of the functions
describe in the namespace that we've defined. To get the resulting output, all
we need to do is run Wrapture against it to get the C++ files:

```sh
wrapture stove.yml
```

Now you can use the Stove class just like you would any other library:

```cpp
#include <Stove.hpp>

// ...

if( Stove::IsModelSupported( 4 ) ) {
  cout << "model 4 stoves are supported" << endl;
}

Stove my_stove (4); // create a stove with four burners

cout << "burner count is: " << my_stove.GetBurnerCount() << endl;

my_stove.SetOvenTemp( 350 );
cout << "current oven temp is: " << my_stove.GetOvenTemp() << endl;

my_stove.SetBurnerLevel( 2, 9 );
cout << "burner 2 level is: " << my_stove.GetBurnerLevel( 2 ) << endl;
```

If you want to run this example, all that remains after using wrapture to
generate the sources is to compile the various sources and run the `stove_usage`
program to see the output:

```sh
# assuming that you're using sh and have g++
g++ -I . stove.c Stove.cpp stove_usage.cpp -o stove_usage_example
./stove_usage_example
```
