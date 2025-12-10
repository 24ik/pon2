## This module implements notice garbage puyos.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ../private/[assign, staticfor]

type Notice* {.pure.} = enum
  ## Notice garbage puyo.
  Small
  Large
  Rock
  Star
  Moon
  Crown
  Comet

# ------------------------------------------------
# Notice Garbage
# ------------------------------------------------

const NoticeUnits: array[Notice, int] = [1, 6, 30, 180, 360, 720, 1440]

func noticeCounts*(
    score, garbageRate: int, useComet = false
): array[Notice, int] {.inline, noinit.} =
  ## Returns the number of notice garbage puyos.
  var counts {.noinit.}: array[Notice, int]

  if score < 0:
    let invCounts = (-score).noticeCounts(garbageRate, useComet)
    staticFor(notice, Notice):
      counts[notice].assign -invCounts[notice]

    return counts

  let highestNotice: Notice
  if useComet:
    highestNotice = Comet
  else:
    highestNotice = Crown
    counts[Comet].assign 0

  var score2 = score div garbageRate
  for notice in countdown(highestNotice, Notice.low):
    let
      unit = NoticeUnits[notice]
      count = score2 div unit

    counts[notice].assign count
    score2.dec unit * count

  counts
