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
  FooE

block: # sum
  check sum(1, 2) == 1 + 2
  check sum(1.0, 2.0, 3.0) == 1.0 + 2.0 + 3.0
  check sum(1, 2, 3, 4) == 1 + 2 + 3 + 4
  check sum(1, 2, 3, 4, 5) == 1 + 2 + 3 + 4 + 5
  check sum(1'u32, 2'u32, 3'u32, 4'u32, 5'u32, 6'u32) ==
    1'u32 + 2'u32 + 3'u32 + 4'u32 + 5'u32 + 6'u32
  check sum(1'd, 2'd, 3'd, 4'd, 5'd, 6'd, 7'd) == 1'd + 2'd + 3'd + 4'd + 5'd + 6'd + 7'd
  check sum(1, 2, 3, 4, 5, 6, 7, 8) == 1 + 2 + 3 + 4 + 5 + 6 + 7 + 8

  check sum({'a', 'b'}, {'c'}, {'a', 'd'}) == {'a', 'b', 'c', 'd'}

  check @[1.0, 2.0].sum == 3.0
  check [4, -2, 0].sum == 2
  check [8'i32].sum == 8'i32
  check newSeq[uint64]().sum == 0'u64

block: # sumIt
  func `+=`(fooSet: var set[Foo], elem: Foo) =
    fooSet.incl elem

  let
    elems = {FooA, FooC}
    nextElems = elems.sumIt set[Foo]({}):
      it.succ
    ordSum = elems.sumIt it.ord

  check nextElems == {FooB, FooD}
  check ordSum == FooA.ord + FooC.ord
