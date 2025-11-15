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

block: # sum, sumIt
  check @[1.0, 2.0].sum == 3.0
  check [4, -2, 0].sum == 2
  check [8'i32].sum == 8'i32
  check newSeq[uint64]().sum == 0'u64

  block:
    let arr: array[Foo, int] = [2, 3, 4, 5]
    check arr.sum(FooB .. FooD) == 12

  block:
    let s = sumIt[Foo, uint](FooB .. FooD):
      it.ord.uint
    check s == 6
