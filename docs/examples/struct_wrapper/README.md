# Struct Wrapping Example

In some cases you may have a struct that is a simple container for data, and
doesn't have a constructor or destructor associated with it. In this case you
can save yourself some work by defining the members of the struct. This will
create a few default constructors for the wrapping class, and allow you to
define functions using the struct as a class.

Consider the following C struct, which is a simple container for a set of
statistics describing a soccer player:

```c
struct player_stats {
  int goals_scored;
  int yellow_cards;
  int red_cards;
};
```

We can create a PlayerStats class using the following description. Note the
'members' field in the equivalent-struct:

```yaml
classes:
  - name: "PlayerStats"
    namespace: "soccer"
    equivalent-struct:
      name: "player_stats"
      includes: "stats.h"
      members:
        - name: "goals_scored"
          type: "int"
        - name: "yellow_cards"
          type: "int"
        - name: "red_cards"
          type: "int"
```

Note the `members` field, which contains the description of the fields that
should be handled by the default constructors. The new class will have a simple
constructor with three parameters, each corresponding to the listed members.
There will also be two other constructors which accept either a struct, or a
struct pointer, and copy all members to the class instantiation.

This is all that's required to generate the basic struct wrapping. However, if
you'd like a default constructor that doesn't require any parameters, then
you'll need to provide a little more information. For each member, just define
a default value. This would look like this:

```yaml
      members:
        - name: "goals_scored"
          type: "int"
          default-value: 0
        - name: "yellow_cards"
          type: "int"
          default-value: 0
        - name: "red_cards"
          type: "int"
          default-value: 0
```

Now it will be much easier to extend this class, as it provides a default
constructor that can be called to initialize a child class. If you only provide
a few default values but not all of them, those will be optional in the
constructor.

Adding a function to our PlayerStats class is the same as with any other
Wrapture class. For example, if we have a simple print function for the stats:

```c
void print_player_stats( struct player_stats *stats );
```

Then we would provide the following function description to get a member
function called `Print`:

```yaml
    functions:
      - name: "Print"
        wrapped-function:
          name: "print_player_stats"
          params:
            - name: "equivalent-struct-pointer"
          includes: "stats.h"
```

All of this results in a C++ class with the following signature.

```cpp
namespace soccer {

  class PlayerStats {
  public:

    struct player_stats equivalent;

    PlayerStats( int goals_scored, int yellow_cards, int red_cards );
    PlayerStats( struct player_stats equivalent );
    PlayerStats( struct player_stats *equivalent );
    void Print( void );
  };

}
```

If you want to run this example, all that remains after using wrapture to
generate the sources is to compile the various sources and run the `stats_usage`
program to see the output:

```sh
# assuming that you're using sh and have g++
g++ -I . stats.c PlayerStats.cpp stats_usage.cpp -o stats_usage_example
./stats_usage_example

# output:
# default player's stats:
#   player scored 0 goals, earned 0 yellow cards, and 0 red cards
# my player's stats:
#   player scored 3 goals, earned 5 yellow cards, and 1 red cards
# their player's stats:
#   player scored 0 goals, earned 4 yellow cards, and 4 red cards
```
