## This module implements helper functions for the marathon mode.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import ../../../core/[pair, pairposition, position]

func toPairsPositions*(str: string): PairsPositions {.inline.} =
  ## Returns the pairs&positions converted from the flattened string.
  collect:
    for i in countup(0, str.len.pred, 2):
      PairPosition(pair: str[i .. i.succ].parsePair, position: None)
