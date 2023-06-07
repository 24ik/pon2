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
      moveNum = 3
      kind = CHAIN_CLEAR
      num = 5.RequirementNumber
      colorNum = 3
      heights = [1.Col: some 0.Natural, none Natural, none Natural, none Natural, some 0.Natural, some 0.Natural]
      puyoNums = (color: 20.Natural, garbage: 2.Natural)
      connect3Nums = (total: none Natural, vertical: some 0.Natural, horizontal: some 1.Natural, lShape: none Natural)
      (nazo, sol) = generate(
        42,
        moveNum,
        (kind: kind, color: some AbstractRequirementColor.ALL, num: some num),
        colorNum,
        heights,
        puyoNums,
        connect3Nums,
        false,
        false).get
      fieldArray = nazo.env.field.toArray

    check nazo.solve == @[sol]
    check nazo.moveNum == moveNum
    check nazo.req == (kind: kind, color: some RequirementColor.ALL, num: some num)
    check ColorPuyo.countIt(nazo.env.colorNum(it) > 0) == colorNum

    for col, height in heights:
      if height.isNone:
        check ((Row.low .. Row.high).mapIt (fieldArray[it][col] != NONE).int).sum > 0
      else:
        if height.get == 0:
          check (Row.low .. Row.high).allIt fieldArray[it][col] == NONE

    check nazo.env.colorNum == puyoNums.color
    check nazo.env.garbageNum == puyoNums.garbage

    check connect3Nums.total.isNone or nazo.env.field.connect3.puyoNum == connect3Nums.total.get * 3
    check connect3Nums.vertical.isNone or nazo.env.field.connect3V.puyoNum == connect3Nums.vertical.get * 3
    check connect3Nums.horizontal.isNone or nazo.env.field.connect3H.puyoNum == connect3Nums.horizontal.get * 3
    check connect3Nums.lShape.isNone or nazo.env.field.connect3L.puyoNum == connect3Nums.lShape.get * 3

    check nazo.env.pairs.toSeq.allIt(not it.isDouble)
