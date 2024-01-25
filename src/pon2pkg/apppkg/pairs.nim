## This module implements pairs database.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[critbits, os, strutils]

const RawPairsTxt =
  staticRead currentSourcePath().parentDir.parentDir.parentDir.parentDir /
    "assets/pairs/haipuyo.txt"

func initPairsDatabase*: CritBitTree[void] {.inline.} =
  ## Returns a new pairs database.
  RawPairsTxt.splitLines.toCritBitTree

when isMainModule:
  import std/sequtils
  echo initPairsDatabase().itemsWithPrefix("rgbb").toSeq.len
