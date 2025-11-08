{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, unittest]
import ../../src/pon2/[core]
import ../../src/pon2/app/[permute]

block: # permute
  let
    nazo = parseNazoPuyo[TsuField](
      """
3連鎖するべし
======
......
......
......
......
......
......
......
......
......
..oo..
..bb..
o.go.o
ggoggg
------
bg|
bg|"""
    ).unsafeValue

    step1gbgb = "gb|12\ngb|12".parseSteps.unsafeValue
    step1gbbg = "gb|12\nbg|21".parseSteps.unsafeValue
    step1bgbg = "bg|21\nbg|21".parseSteps.unsafeValue
    step2 = "gg|1N\nbb|2N".parseSteps.unsafeValue

  # no limitations
  check nazo.permute(@[], allowDblNotLast = true, allowDblLast = true).mapIt(
    it.puyoPuyo.steps
  ) == @[step2, step1gbgb]

  # w/ fixIndices
  check nazo.permute(@[1], allowDblNotLast = true, allowDblLast = true).mapIt(
    it.puyoPuyo.steps
  ) == @[step1gbbg]
  check nazo.permute(@[0, 1], allowDblNotLast = true, allowDblLast = true).mapIt(
    it.puyoPuyo.steps
  ) == @[step1bgbg]

  # not allow double (last)
  check nazo.permute(@[], allowDblNotLast = true, allowDblLast = false).mapIt(
    it.puyoPuyo.steps
  ) == @[step1gbgb]

  # not allow double (not last)
  check nazo.permute(@[], allowDblNotLast = false, allowDblLast = true).mapIt(
    it.puyoPuyo.steps
  ) == @[step1gbgb]
