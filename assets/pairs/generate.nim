## This module implements the generation of pairs assets.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[os, sequtils, strutils, sugar]

const
  PairsCount = 65536
  PairCount = 128
  LineLen = PairCount * 2

when isMainModule:
  let
    rawPath = currentSourcePath() /../ "raw.txt"
    rawLines = rawPath.readFile.splitLines
  doAssert rawLines.len == PairsCount
  doAssert rawLines.allIt it.len == LineLen

  # marathon; axis and child swapped
  block:
    let pairStrs = collect:
      for line in rawLines:
        for i in countup(0, LineLen.pred, 2):
          line[i.succ] & line[i]
    doAssert pairStrs.len == PairCount * PairsCount
    doAssert pairStrs.allIt it.len == 2

    let lines = collect:
      for pairsIdx in 0..<PairsCount:
        join pairStrs[pairsIdx * PairCount ..< pairsIdx.succ * PairCount]
    doAssert lines.len == PairsCount
    doAssert lines.allIt it.len == LineLen

    (rawPath /../ "swap.txt").writeFile lines.join "\n"
