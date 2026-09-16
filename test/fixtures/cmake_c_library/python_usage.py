#!/usr/bin/env python3

import py_cmake_c_lib

result = py_cmake_c_lib.CmakeCLib.add(3, 4)
if result != 7:
    print(f"result was {result} instead of 7!")
    exit(1)
