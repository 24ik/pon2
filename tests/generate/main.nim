import deques
import math
import options
import sequtils
import unittest

import nazopuyo_core
import puyo_core

import ../../src/pon2pkg/core/generate
import ../../src/pon2pkg/core/solve

proc main* =
  # ------------------------------------------------
  # Generate
  # ------------------------------------------------

  # generate
  block:
    let
      rule = TSU
      moveCount = 3
      kind = CHAIN_CLEAR
      num = 5.RequirementNumber
      colorCount = 3
      heights = [some 0.Natural, none Natural, none Natural, none Natural, some 0.Natural, some 0.Natural]
      puyoCounts = (color: 20.Natural, garbage: 2.Natural)
      connect3Counts =
        (total: none Natural, vertical: some 0.Natural, horizontal: some 1.Natural, lShape: none Natural)
      nazo = generate(
        42,
        rule,
        moveCount,
        (kind: kind, color: some AbstractRequirementColor.ALL, number: some num),
        colorCount,
        heights,
        puyoCounts,
        connect3Counts,
        false,
        false).get
      fieldArray = nazo.question.environment.field.toArray

    check nazo.question.solve == @[nazo.answer]
    check nazo.question.moveCount == moveCount
    check nazo.question.requirement == (kind: kind, color: some RequirementColor.ALL, number: some num)
    check ColorPuyo.countIt(nazo.question.environment.count(it) > 0) == colorCount

    for col, height in heights:
      if height.isNone:
        check ((Row.low .. Row.high).mapIt (fieldArray[it][col] != NONE).int).sum > 0
      else:
        if height.get == 0:
          check (Row.low .. Row.high).allIt fieldArray[it][col] == NONE

    check nazo.question.environment.countColor == puyoCounts.color
    check nazo.question.environment.countGarbage == puyoCounts.garbage

    check connect3Counts.total.isNone or nazo.question.environment.field.connect3.countPuyo ==
      connect3Counts.total.get * 3
    check connect3Counts.vertical.isNone or nazo.question.environment.field.connect3V.countPuyo ==
      connect3Counts.vertical.get * 3
    check connect3Counts.horizontal.isNone or nazo.question.environment.field.connect3H.countPuyo ==
      connect3Counts.horizontal.get * 3
    check connect3Counts.lShape.isNone or nazo.question.environment.field.connect3L.countPuyo ==
      connect3Counts.lShape.get * 3

    check nazo.question.environment.pairs.toSeq.allIt(not it.isDouble)
