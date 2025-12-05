{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, unittest]
import ../../src/pon2/[core]
import ../../src/pon2/app/[permute]

block: # permute
  let
    nazoPuyo =
      """
ちょうど3連鎖するべし
======
[通]
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
bg|""".parseNazoPuyo.unsafeValue

    step1gbgb = "gb|12\ngb|12".parseSteps.unsafeValue
    step1gbbg = "gb|12\nbg|21".parseSteps.unsafeValue
    step1bgbg = "bg|21\nbg|21".parseSteps.unsafeValue
    step2 = "gg|1N\nbb|2N".parseSteps.unsafeValue

  # no limitations
  check nazoPuyo.permute(@[], allowDoubleNotLast = true, allowDoubleLast = true).mapIt(
    it.puyoPuyo.steps
  ) == @[step2, step1gbgb]

  # w/ fixIndices
  check nazoPuyo.permute(@[1], allowDoubleNotLast = true, allowDoubleLast = true).mapIt(
    it.puyoPuyo.steps
  ) == @[step1gbbg]
  check nazoPuyo
  .permute(@[0, 1], allowDoubleNotLast = true, allowDoubleLast = true)
  .mapIt(it.puyoPuyo.steps) == @[step1bgbg]

  # not allow double (last)
  check nazoPuyo.permute(@[], allowDoubleNotLast = true, allowDoubleLast = false).mapIt(
    it.puyoPuyo.steps
  ) == @[step1gbgb]

  # not allow double (not last)
  check nazoPuyo.permute(@[], allowDoubleNotLast = false, allowDoubleLast = true).mapIt(
    it.puyoPuyo.steps
  ) == @[step1gbgb]
