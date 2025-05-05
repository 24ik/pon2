{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/private/[math2]

type Foo = enum
  FooA
  FooB
  FooC
  FooD

block: # sum2, sum2It
  check @[1.0, 2.0].sum2 == 3.0
  check [4, -2, 0].sum2 == 2
  check [8'i32].sum2 == 8'i32
  check newSeq[uint64]().sum2 == 0'u64

  block:
    let arr: array[Foo, int] = [2, 3, 4, 5]
    check arr.sum2(FooB .. FooD) == 12

  block:
    let s = sum2It[Foo, uint](FooB .. FooD):
      it.ord.uint
    check s == 6
