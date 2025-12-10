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
      let fooBar = foo + bar

    check fooBar == fooA + barA

  block:
    let
      fooA = 10
      fooB = 20

    var fooBarA, fooBarB: int
    expandAB fooBar, foo:
      fooBar = foo.succ + _

    check fooBarA == fooA.succ + 0
    check fooBarB == fooB.succ + 1
