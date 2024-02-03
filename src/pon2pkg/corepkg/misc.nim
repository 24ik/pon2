## This module implements miscellaneous things.
##
## Compile Options:
## | Option                          | Description                 | Default  |
## | ------------------------------- | --------------------------- | -------- |
## | `-d:Pon2TsuGarbageRate=<int>`   | Garbage rate in Tsu rule.   | `70`     |
## | `-d:Pon2WaterGarbageRate=<int>` | Garbage rate in Water rule. | `90`     |
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ./[rule]

const
  Pon2TsuGarbageRate {.intdefine.} = 70
  Pon2WaterGarbageRate {.intdefine.} = 90

static:
  doAssert Pon2TsuGarbageRate >= 1
  doAssert Pon2WaterGarbageRate >= 1

type
  SimulatorHost* {.pure.} = enum
    ## URI host of the web simulator.
    Izumiya = "izumiya-keisuke.github.io"
    Ishikawa = "ishikawapuyo.net"
    Ips = "ips.karou.jp"

  SimulatorKind* {.pure.} = enum
    ## Kind of the web simulator.
    Regular = "r"
    Nazo = "n"

  SimulatorMode* {.pure.} = enum
    ## Mode of the web simulator.
    Edit = "e"
    Play = "p"
    Replay = "r"

  NoticeGarbage* {.pure.} = enum
    ## Notice garbage.
    Small
    Big
    Rock
    Star
    Moon
    Crown
    Comet

const GarbageRates*: array[Rule, Positive] = [
  Pon2TsuGarbageRate.Positive, Pon2WaterGarbageRate]
