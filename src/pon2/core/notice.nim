## This module implements notice garbages.
##
## Compile Options:
## | Option                            | Description                 | Default  |
## | --------------------------------- | --------------------------- | -------- |
## | `-d:pon2.garbagerate.tsu=<int>`   | Garbage rate in Tsu rule.   | `70`     |
## | `-d:pon2.garbagerate.water=<int>` | Garbage rate in Water rule. | `90`     |
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ./[rule]

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
  GarbageRates*: array[Rule, Positive] = [TsuGarbageRate.Positive, WaterGarbageRate]

# ------------------------------------------------
# Notice Garbage
# ------------------------------------------------

const NoticeUnits: array[NoticeGarbage, Natural] = [1, 6, 30, 180, 360, 720, 1440]

func noticeGarbageCounts*(
    score: Natural, rule: Rule, useComet = false
): array[NoticeGarbage, int] {.inline.} =
  ## Returns the number of notice garbages.
  result[Comet] = 0

  let highestNotice = if useComet: Comet else: Crown
  var score2 = score div GarbageRates[rule]
  for notice in countdown(highestNotice, NoticeGarbage.low):
    let unit = NoticeUnits[notice]
    result[notice] = score2 div unit
    score2.dec result[notice] * unit
