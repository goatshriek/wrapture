# Struct Wrapping Example

In some cases, you may have a struct that is a simple container for data, and
doesn't have a constructor or destructor associated with it. In this case, you
can save some work by simply defining the members of the struct. This will
create a default constructor for the wrapping class, and allow you to define
functions using the struct as a class.

Let's use the following C struct, which is a simple container for a set of
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
      includes:
        - "stats.h"
      members:
        - name: "goals_scored"
          type: "int"
        - name: "yellow_cards"
          type: "int"
        - name: "red_cards"
          type: "int"
```

Note the `members`field, which contains a description of the fields that should
be handled by the default constructor and destructor. The new class will have a
simple constructor with three parameters, each corresponding to the listed
members.

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
          includes:
            - "stats.h"
```

If you want to run this example, all that remains after using wrapture to
generate the sources is to compile the various sources and run the `stats_usage`
program to see the output:

```sh
# assuming that you're using sh and have g++
g++ -I . stats.c PlayerStats.cpp stats_usage.cpp -o stats_usage_example
./stats_usage_example
```
