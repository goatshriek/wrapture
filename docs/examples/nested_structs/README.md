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
with a class for each of the pieces as well. We start with the component
classes first:

```yaml
classes:
  - name: "IceMaker"
    namespace: "kitchen"
    includes: "fridge.h"
```
