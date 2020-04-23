---
layout: home
title: "Wrapture at a glance"
---

Wrapture allows C libraries to be wrapped in C++ for an object-oriented look and
feel. To get a feel for how different things can be done, check out the
examples:

 * **[Basic Usage](./examples/basic.html)** Just the essentials!
 * **[Constants](./examples/constants.html)** Defining constants within a class.
 * **[Enumerations](./examples/enumerations.html)** Create enumeration classes
   from C-style enumerations, or entirely new ones based on arbitrary values.
 * **[Exceptions](./examples/exceptions.html)** Define error conditions and
   the exceptions that should be thrown when they are encountered.
 * **[Inheritance](./examples/inheritance.html)** Have generated classes inherit
   from other generated classes or other existing ones.
 * **[Nested Structs](./examples/nested_structs.html)** Specific examples of
   hierarchical structures and their corresponding generated classes.
 * **[Overloaded Structs](./examples/overloaded_struct.html)** Have a single
   struct correlate to multiple classes, depending on custom conditions.
 * **[Struct Wrapper](./examples/struct_wrapper.html)** Have a wrapping class
   automatically generated for a struct based on its members.
 * **[Templates](./examples/templates.html)** Define reusable specifications
   that can make large wrapping projects much faster and more maintainable.

If you really want to get into the weeds, you can check out the
[RDoc documentation](./rdoc) for all of the details.

# The Future

While the current state of Wrapture is admittedly simple, the future direction
is much more ambitious. The ultimate goal is to use the same specifications to
generate APIs for a variety of languages, and even to allow operation between
languages with C being used transparently behind the scenes to translate. Check
out the [project roadmap](./roadmap.html) to see what the next steps are.
