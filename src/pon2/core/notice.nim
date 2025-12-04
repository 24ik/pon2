## This module implements notice garbage puyos.
##
## Compile Options:
## | Option                            | Description                 | Default  |
## | --------------------------------- | --------------------------- | -------- |
## | `-d:pon2.garbagerate.tsu=<int>`   | Garbage rate in Tsu rule.   | `70`     |
## | `-d:pon2.garbagerate.water=<int>` | Garbage rate in Water rule. | `90`     |
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ./[rule]
import ../private/[assign, staticfor]

export notice, rule

type Notice* {.pure.} = enum
  ## Notice garbage puyo.
  Small
  Large
  Rock
  Star
  Moon
  Crown
  Comet

const
  TsuGarbageRate {.define: "pon2.garbagerate.tsu".} = 70
  WaterGarbageRate {.define: "pon2.garbagerate.water".} = 90
  GarbageRates*: array[Rule, int] = [TsuGarbageRate, WaterGarbageRate]

static:
  for rate in GarbageRates:
    doAssert rate > 0

# ------------------------------------------------
# Notice Garbage
# ------------------------------------------------

const NoticeUnits: array[Notice, int] = [1, 6, 30, 180, 360, 720, 1440]

func noticeCounts*(
    score: int, rule: Rule, useComet = false
): array[Notice, int] {.inline, noinit.} =
  ## Returns the number of notice garbage puyos.
  var counts {.noinit.}: array[Notice, int]

  if score < 0:
    let invCounts = (-score).noticeCounts(rule, useComet)
    staticFor(notice, Notice):
      counts[notice].assign -invCounts[notice]

    return counts

  let highestNotice: Notice
  if useComet:
    highestNotice = Comet
  else:
    highestNotice = Crown
    counts[Comet].assign 0

  var score2 = score div GarbageRates[rule]
  for notice in countdown(highestNotice, Notice.low):
    let
      unit = NoticeUnits[notice]
      count = score2 div unit

    counts[notice].assign count
    score2.dec unit * count

  counts
