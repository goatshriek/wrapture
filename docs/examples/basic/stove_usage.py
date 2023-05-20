#!/usr/bin/env python

import kitchen

my_stove = kitchen.Stove(4)

print('burner count is: %d\n' % my_stove.GetBurnerCount())

my_stove.SetOvenTemp(350)
print('current oven temp is: %d\n' % my_stove.GetOvenTemp())

my_stove.SetBurnerLevel(2, 9);
print('burner 2 level is: %d\n' % my_stove.GetBurnerLevel(2))
