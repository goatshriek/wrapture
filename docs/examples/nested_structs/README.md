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
      wrapped-function:
        name: "new_fridge"
        params:
          name: "temperature"
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
            - name: "new_ice_maker"
              type: "struct ice_maker *"
```
