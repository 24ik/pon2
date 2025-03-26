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

import std/[strformat]
import ./[rule]
import ../private/[assign3, results2]

type NoticeGarbage* {.pure.} = enum
  ## Notice garbage puyo.
  Small
  Big
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

const NoticeUnits: array[NoticeGarbage, int] = [1, 6, 30, 180, 360, 720, 1440]

func noticeGarbageCnts*(
    score: int, rule: Rule, useComet = false
): Res[array[NoticeGarbage, int]] {.inline.} =
  ## Returns the number of notice garbage puyos.
  if score < 0:
    return err "`score` should be non-negative, but got {score}".fmt

  var cnts {.noinit.}: array[NoticeGarbage, int]

  let highestNotice: NoticeGarbage
  if useComet:
    highestNotice = Comet
  else:
    highestNotice = Crown
    cnts[Comet].assign 0

  var score2 = score div GarbageRates[rule]
  for notice in countdown(highestNotice, NoticeGarbage.low):
    let
      unit = NoticeUnits[notice]
      cnt = score2 div unit

    cnts[notice].assign cnt
    score2.dec unit * cnt

  ok cnts
