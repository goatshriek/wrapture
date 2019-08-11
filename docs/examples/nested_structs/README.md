# Nested Structs Example

It's a common pattern to see structs that contain pointers to other structs in
them. This is the standard composition pattern, and it is natural to wrap APIs
that use this to have composition themselves. Wrapture supports this in a
natural way, with only a few extra pieces of information in the specification.

Consider a description of a refrigerator made up of the three basic components
in addition to the fridge attributes: the icemaker, the water filter, and the
freezer.

```c
struct fridge {
  struct ice_maker *ice;
  struct water_filter *filter;
  struct freezer *freezer;
};
```

We would like to create a specification that generates the Fridge class along
with a class for each of the pieces. We start with the component classes:

```yaml
classes:
  - name: "IceMaker"
    namespace: "kitchen"
    includes: "fridge.h"
    equivalent-struct:
      name: "ice_maker"
  - name: "WaterFilter"
    namespace: "kitchen"
    includes: "fridge.h"
    equivalent-struct:
      name: "water_filter"
  - name: "Freezer"
    namespace: "kitchen"
    includes: "fridge.h"
    equivalent-struct:
      name: "freezer"
```

Next we define the top level class, which makes use of these three types in its
functions. There is no reason that we could not have defined this class first
and the components second, either order will work.

```yaml
  - name: "Fridge"
    namespace: "kitchen"
    includes: "fridge.h"
    equivalent-struct:
      name: "fridge"
    constructors:
      - wrapped-function:
          name: "new_fridge"
          params:
            - name: "temperature"
              type: "int"
          return:
            type: "equivalent-struct-pointer"
    functions:
      - name: "AddIceMaker"
        params:
          - name: "new_ice_maker"
            type: "IceMaker"
        wrapped-function:
          name: "add_ice_maker_to_fridge"
          params:
            - name: "equivalent-struct-pointer"
            - name: "new_ice_maker"
              type: "struct ice_maker *"
      - name: "AddWaterFilter"
        params:
          - name: "new_filter"
            type: "WaterFilter"
        wrapped-function:
          name: "add_water_filter_to_fridge"
          params:
            - name: "equivalent-struct-pointer"
            - name: "new_filter"
              type: "struct water_filter *"
      - name: "AddFreezer"
        params:
          - name: "new_freezer"
            type: "Freezer"
        wrapped-function:
          name: "add_freezer_to_fridge"
          params:
            - name: "equivalent-struct-pointer"
            - name: "new_freezer"
              type: "struct freezer *"
```

Wrapture detects that the type of the params in the wrapped functions are
derivatives of the C++ parameters, and performs the appropriate cast on them
when the wrapper is called. For example, in the `AddFreezer` function the
`new_freezer` parameter will be converted to the underlying pointer of the
freezer class using `new_freezer.equivalent`, as we can see in the generated
definition here:

```cpp

```

If you want to run this example, all that remains after using wrapture to
generate the sources is to compile them and run the `fridge_usage` program
to see the output:

```sh
# generating the wrapped sources
wrapture fridge.yml

# compiling (assumes that you're using sh and have g++)
g++ -I . fridge.c Fridge.cpp fridge_usage.cpp -o fridge_usage_example
./fridge_usage_example
```
