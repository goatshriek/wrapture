#ifndef __FRIDGE_H
#define __FRIDGE_H

struct fridge {
  struct ice_maker *ice;
  struct water_filter *filter;
  struct freezer *freezer;
};

#endif
