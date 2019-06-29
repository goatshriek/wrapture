# Struct Wrapping Example

In some cases, you may have a struct that is a simple container for data, and
doesn't have a constructor or destructor associated with it. In this case, you
can save some work by simply defining the members of the struct. This will
create a default constructor for the wrapping class, and allow you to define
functions using the struct as a class.

Let's use the following C struct, which is just a container for a set of
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
```
