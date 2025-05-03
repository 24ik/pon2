{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[macros, sugar, unittest]
import ../../src/pon2/private/[macros2]

# ------------------------------------------------
# Replace
# ------------------------------------------------

block: # replaced, replace
  macro foo2bar(body: untyped): untyped =
    body.replaced("foo".ident, "bar".ident)

  macro hoge2fuga(body: untyped): untyped =
    body.dup(replace(_, "hoge".ident, "fuga".ident))

  block:
    let bar = 1
    foo2bar:
      let res = foo + 2 * foo.succ
    check res == 5

  block:
    let fuga = "fuga"
    hoge2fuga:
      let res = hoge & hoge
    check res == "fugafuga"

# ------------------------------------------------
# Expand
# ------------------------------------------------

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

# ------------------------------------------------
# Case
# ------------------------------------------------

block: # staticCase
  func nextPow2(x: static int): int =
    staticCase:
      case x
      of 0, 1:
        1
      of 2:
        2
      of 3, 4:
        4
      of 5..8:
        8
      elif 9 <= x and x < 17:
        16
      else:
        -1

  check 1.nextPow2 == 1
  check 2.nextPow2 == 2
  check 3.nextPow2 == 4
  check 7.nextPow2 == 8
  check 13.nextPow2 == 16
  check 18.nextPow2 == -1
