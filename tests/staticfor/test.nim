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

block: # staticFor (slice)
  block: # enum
    var enumSet = set[MyEnum]({})
    staticFor(elem, Elem1 .. Elem3):
      enumSet.incl elem

    check enumSet == {Elem1 .. Elem3}

  block: # int
    var sum = 0
    staticFor(val, 1 .. 5):
      sum.inc val

    check sum == 15

block: # staticFor (openArray)
  block: # enum
    var enumSet = set[MyEnum]({})
    staticFor(elem, [Elem4, Elem0]):
      enumSet.incl elem

    check enumSet == {Elem0, Elem4}

  block: # char
    var str = ""
    staticFor(elem, @['t', 'e', 's', 't']):
      str &= elem

    check str == "test"

block: # staticFor (set)
  block: # enum
    var enumSet = set[MyEnum]({})
    staticFor(elem, {Elem2, Elem4}):
      enumSet.incl elem

    check enumSet == {Elem2, Elem4}

  block: # int8
    var sum = 0'i8
    staticFor(val, {3'i8, 2'i8, 4'i8}):
      sum.inc val

    check sum == 9

block: # staticFor (type)
  block: # enum
    var enumSet = set[MyEnum]({})
    staticFor(elem, MyEnum):
      enumSet.incl elem

    check enumSet == {Elem0 .. Elem4}
