{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/private/[expand]

block: # defineExpand
  defineExpand "A", "A"
  defineExpand "AB", "A", "B"

  block:
    let
      fooA = 1
      barA = 2

    expandA foo, bar:
      let res = foo + bar

    check res == fooA + barA

  block:
    let
      fooA = 10
      fooB = 20

    var resA, resB: int
    expandAB res, foo:
      res = foo.succ + _

    check resA == fooA.succ + 0
    check resB == fooB.succ + 1
