## This module implements helper functions for the marathon mode.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[deques]
import ../../../core/[pair, pairposition, position]

const
  MatchResultPairsCountPerPage* = 10
  AllPairsCount* = 65536

func toPairsPositions*(str: string): PairsPositions {.inline.} =
  ## Returns the pairs&positions converted from the flattened string.
  result = initDeque[PairPosition](str.len div 2)
  for idx in countup(0, str.len.pred, 2):
    # NOTE: marathon mode string has the swapped order (child, axis, child, axis, ...)
    result.addLast PairPosition(
      pair: (str[idx.succ] & str[idx]).parsePair, position: None
    )
