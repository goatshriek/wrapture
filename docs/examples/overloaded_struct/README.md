# Overloaded Struct Example

C structs do not have a pattern for inheritance, and as such it is a common
pattern for them to be differentiated from one another using something like a
type code or enumeration. However, in an object oriented language the more
common pattern is to create a parent class and inherit from it. This is most
obvious in the exception classes of most languages, where different kinds of
errors are different classes which are children of the main exception or error
classes.

Wrapture provides a way to distinguish between different types of a struct so
that it will be translated to the correct class. This example demonstrates the
concept using the most common exception pattern, but it can be used in other
ways as needed.

For this exampmle, we will consider an error struct that consists of an integer
error code and a string message describing the problem.

```c
struct error {
  int code;
  const char *message;
};
```
