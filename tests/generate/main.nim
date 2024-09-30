{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[options, sequtils, unittest]
import ../../src/pon2/app/[generate {.all.}, solve]
import
  ../../src/pon2/core/
    [cell, field, fieldtype, mark, nazopuyo, pair, pairposition, puyopuyo, requirement]
import ../../src/pon2/private/[misc]

proc main*() =
  # ------------------------------------------------
  # Generate
  # ------------------------------------------------

  # generate
  block:
    {.push warning[ProveInit]: off.}
    {.cast(uncheckedAssign).}:
      let
        moveCount = 2
        kind = ChainClear
        num = 5.RequirementNumber
        colorCount = 3
        heights: array[Column, Option[Natural]] = [
          some 0.Natural,
          none Natural,
          none Natural,
          none Natural,
          some 0.Natural,
          some 0.Natural,
        ]
        puyoCounts = (color: none Natural, garbage: 2.Natural)
        connect2Counts =
          (total: none Natural, vertical: some 1.Natural, horizontal: some 0.Natural)
        connect3Counts = (
          total: none Natural,
          vertical: some 0.Natural,
          horizontal: some 1.Natural,
          lShape: none Natural,
        )
        nazo = generate[TsuField](
          42,
          GenerateRequirement(
            kind: kind, color: GenerateRequirementColor.All, number: num
          ),
          moveCount,
          colorCount,
          heights,
          puyoCounts,
          connect2Counts,
          connect3Counts,
          false,
          false,
        )
        fieldArr = nazo.puyoPuyo.field.toArray
    {.pop.}

    check nazo.solve == @[nazo.puyoPuyo.pairsPositions]
    check nazo.mark == Accept
    check nazo.moveCount == moveCount
    {.cast(uncheckedAssign).}:
      check nazo.requirement ==
        Requirement(kind: kind, color: RequirementColor.All, number: num)
    check (ColorPuyo.low .. ColorPuyo.high).countIt(nazo.puyoPuyo.puyoCount(it) > 0) ==
      colorCount

    for col, height in heights:
      if height.isNone:
        check ((Row.low .. Row.high).mapIt int fieldArr[it][col] != None).sum2 > 0
      else:
        if height.get == 0:
          check (Row.low .. Row.high).allIt fieldArr[it][col] == None

    check nazo.puyoPuyo.colorCount == num * 4
    check nazo.puyoPuyo.garbageCount == puyoCounts.garbage

    check nazo.puyoPuyo.field.connect2V.colorCount == connect2Counts.vertical.get * 2
    check nazo.puyoPuyo.field.connect2H.colorCount == connect2Counts.horizontal.get * 2
    check nazo.puyoPuyo.field.connect3V.colorCount == connect3Counts.vertical.get * 3
    check nazo.puyoPuyo.field.connect3H.colorCount == connect3Counts.horizontal.get * 3

    check nazo.puyoPuyo.pairsPositions.allIt(not it.pair.isDouble)
