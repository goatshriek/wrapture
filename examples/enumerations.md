# Enumeration Example

Enumerations are a common tool in many languages to define a known set of values
for use in a library. While these do exist in C code already, the mechanics are
slightly different depending on the target language. Wrapture provides a way to
describe the enumeration you would like to be generated, optionally supplying
values from the original to make sure the two are compatible. Fortunately, this
is one of the more straightforward things to do with Wrapture.

Let's say that we have an enumeration of the types of fruit sold at a particular
store. We define the enumerationw ith a name and a list of elements in a
top-level key named `enums` that is at the same level as the familiar `classes`
key used to describe classes.

```yaml
enums:
  - name: "Fruit"
    elements:
      - name: "apple"
      - name: "banana"
      - name: "grape"
      - name: "orange"
```

Simple, right? Maybe too simple. Let's throw a wrinkle or two in there.

Let's say that our store actually sells all of the fruit from two different
vendors, in addition to some sourced by our own farmers. They each provide their
list of possible fruits in a header file of their own, like so:

```c
// vendor 1: citrus_mangiamo.h
enum citrus_mangiamo_fruits {
  MANGIAMO_GRAPEFRUIT = 41,
  MANGIAMO_LIME = 42,
  MANGIAMO_LEMON = 43,
  MANGIAMO_ORANGE = 44,
  MANGIAMO_TANGELO = 45
};
```

```c
// vendor 2: seedless_desire.h
enum seedless_desire_fruits {
  DESIRE_BANANA = 31,
  DESIRE_GRAPE = 32,
  DESIRE_WATERMELON = 33
};
```

Note that we know here that the underlying integer values don't overlap. If they
did, then we wouldn't be able to use the exact values as they would conflict
with each other in a single enumeration.

Of course we only want a single generated enumeration, and all of the elements
should be the same. We also want the elements to be compatible with those in the
original enumerations, where they exist. This leads us to the following spec:

```yaml
enums:
  - name: "Fruit"
    elements:
      - name: "apple"
      - name: "banana"
        includes: "seedless_desire.h"
        value: "DESIRE_BANANA"
      - name: "grape"
        includes: "seedless_desire.h"
        value: "DESIRE_GRAPE"
      - name: "grapefruit"
        includes: "citrus_mangiamo.h"
        value: "MANGIAMO_GRAPEFRUIT"
      - name: "lemon"
        includes: "citrus_mangiamo.h"
        value: "MANGIAMO_LEMON"
      - name: "lime"
        includes: "citrus_mangiamo.h"
        value: "MANGIAMO_LIME"
      - name: "orange"
        includes: "citrus_mangiamo.h"
        value: "MANGIAMO_ORANGE"
      - name: "tangelo"
        includes: "citrus_tangelo.h"
        value: "MANGIAMO_GRAPEFRUIT"
      - name: "watermelon"
        includes: "seedless_desire.h"
        value: "DESIRE_WATERMELON"
```

This can be compacted a bit by simply making the two includes apply to the
entire enumeration instead of each element. There is no difference between the
two, other than preferred style.

```yaml
enums:
  - name: "Fruit"
    includes:
      - "citrus_mangiamo.h"
      - "seedless_desire.h"
    elements:
      - name: "apple"
      - name: "banana"
        value: "DESIRE_BANANA"
      - name: "grape"
        value: "DESIRE_GRAPE"
      - name: "grapefruit"
        value: "MANGIAMO_GRAPEFRUIT"
      - name: "lemon"
        value: "MANGIAMO_LEMON"
      - name: "lime"
        value: "MANGIAMO_LIME"
      - name: "orange"
        value: "MANGIAMO_ORANGE"
      - name: "tangelo"
        value: "MANGIAMO_GRAPEFRUIT"
      - name: "watermelon"
        value: "DESIRE_WATERMELON"
```

This will generate an enumeration class like this:

```cpp
enum class Fruit {
  apple,
  apricot,
  banana = DESIRE_BANANA,
  grape = DESIRE_GRAPE,
  grapefruit = MANGIAMO_GRAPEFRUIT,
  lemon = MANGIAMO_LEMON,
  lime = MANGIAMO_LIME,
  orange = MANGIAMO_ORANGE,
  tangelo = MANGIAMO_GRAPEFRUIT,
  watermelon = DESIRE_WATERMELON
};
```

The generated enumeration can then be used just as any other within the target
language, as demonstrated in the following C++ snippet:

```cpp
# will be true
if( static_cast<int>( Fruit::watermelon ) == DESIRE_WATERMELON ) {
  cout << "Fruit::watermelon is equal to DESIRE_WATERMELON" << endl;
}

# will also be true
if( Fruit::lime == Fruit(MANGIAMO_LIME) ) {
  cout << "Fruit::lime is equal to MANGIAMO_LIME" << endl;
}
```

Of course you will either need to cast the enumerators to integers or create a
Fruit when you need to compare with the original values. Otherwise, you can work
with the enum class just as you would with any other enum!

If you'd like to run this example in its entirety, you can do so with the
following invocations:

```sh
# generating the wrapper source code
wrapture fruit.yml

# assuming that you're using sh and have g++
g++ -I . fruit_usage.cpp -fruit_usage_example

./fruit_usage_example
# generates the following output:
```
