{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[options, sequtils, unittest]
import ../../src/pon2pkg/corepkg/[cell, field, environment, misc, pair]
import ../../src/pon2pkg/nazopuyopkg/[generate {.all.}, mark, nazopuyo, solve]
import ../../src/pon2pkg/private/[misc]

proc main* =
  # ------------------------------------------------
  # Generate
  # ------------------------------------------------

  # generate
  block:
    {.push warning[ProveInit]: off.}
    let
      moveCount = 3
      kind = ChainClear
      num = 5.RequirementNumber
      colorCount = 3
      heights: array[Column, Option[Natural]] = [
        some 0.Natural, none Natural, none Natural, none Natural,
        some 0.Natural, some 0.Natural]
      puyoCounts = (color: 20.Natural, garbage: 2.Natural)
      connect3Counts = (total: none Natural, vertical: some 0.Natural,
                        horizontal: some 1.Natural, lShape: none Natural)
      genRes = generate[TsuField](
        42, GenerateRequirement(
          kind: kind, color: some GenerateRequirementColor.All,
          number: some num),
        moveCount, colorCount, heights, puyoCounts, connect3Counts, false,
        false, 1)
      nazo = genRes.question
      fieldArr = nazo.environment.field.toArray
    {.pop.}

    check nazo.solve == @[genRes.answer]
    check genRes.answer.mark(nazo) == Accept
    check nazo.moveCount == moveCount
    check nazo.requirement == Requirement(
      kind: kind, color: some RequirementColor.All, number: some num)
    check (ColorPuyo.low..ColorPuyo.high).countIt(
      nazo.environment.puyoCount(it) > 0) == colorCount

    for col, height in heights:
      if height.isNone:
        check ((Row.low..Row.high).mapIt int fieldArr[it][col] != None).sum > 0
      else:
        if height.get == 0:
          check (Row.low..Row.high).allIt fieldArr[it][col] == None

    check nazo.environment.colorCount == puyoCounts.color
    check nazo.environment.garbageCount == puyoCounts.garbage

    check nazo.environment.field.connect3V.colorCount ==
      connect3Counts.vertical.get * 3
    check nazo.environment.field.connect3H.colorCount ==
      connect3Counts.horizontal.get * 3

    check nazo.environment.pairs.toSeq.allIt(not it.isDouble)
