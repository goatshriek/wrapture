#!/usr/bin/env python3

import cmake_c_lib

result = cmake_c_lib.CmakeCLib.Add(3, 4)
if result != 7:
    print(f"result was {result} instead of 7!")
    exit(1)
