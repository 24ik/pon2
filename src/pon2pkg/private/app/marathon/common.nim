## This module implements helper functions for the marathon mode.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import ../../../core/[pair, pairposition, position]

const
  MatchResultPairsCountPerPage* = 10
  AllPairsCount* = 65536

func toPairsPositions*(str: string): PairsPositions {.inline.} =
  ## Returns the pairs&positions converted from the flattened string.
  collect:
    for i in countup(0, str.len.pred, 2):
      let s = str[i .. i.succ]
      PairPosition(pair: s.parsePair, position: None)
