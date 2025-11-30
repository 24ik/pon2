{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/private/[math]

type Foo = enum
  FooA
  FooB
  FooC
  FooD

block: # sum
  check sum(1, 2) == 1 + 2
  check sum(1.0, 2.0, 3.0) == 1.0 + 2.0 + 3.0
  check sum(1, 2, 3, 4) == 1 + 2 + 3 + 4
  check sum(1, 2, 3, 4, 5) == 1 + 2 + 3 + 4 + 5
  check sum(1'u32, 2'u32, 3'u32, 4'u32, 5'u32, 6'u32) ==
    1'u32 + 2'u32 + 3'u32 + 4'u32 + 5'u32 + 6'u32
  check sum(1'd, 2'd, 3'd, 4'd, 5'd, 6'd, 7'd) == 1'd + 2'd + 3'd + 4'd + 5'd + 6'd + 7'd
  check sum(1, 2, 3, 4, 5, 6, 7, 8) == 1 + 2 + 3 + 4 + 5 + 6 + 7 + 8

block: # sum, sumIt
  check @[1.0, 2.0].sum == 3.0
  check [4, -2, 0].sum == 2
  check [8'i32].sum == 8'i32
  check newSeq[uint64]().sum == 0'u64

  block:
    let arr: array[Foo, int] = [2, 3, 4, 5]
    check arr.sum(FooB .. FooD) == 12
