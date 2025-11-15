{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/private/[staticfor]

type MyEnum {.pure.} = enum
  Elem0
  Elem1
  Elem2
  Elem3
  Elem4

block: # slice
  var enumSet = set[MyEnum]({})
  staticFor(elem, Elem1 .. Elem3):
    enumSet.incl elem

  check enumSet == {Elem1 .. Elem3}

block: # typedesc
  var enumSet = set[MyEnum]({})
  staticFor(elem, MyEnum):
    enumSet.incl elem

  check enumSet == {Elem0 .. Elem4}
