## This module implements miscellaneous things.
##
## Compile Options:
## | Option                          | Description                 | Default  |
## | ------------------------------- | --------------------------- | -------- |
## | `-d:Pon2WaterHeight=<int>`      | Height of the water.        | `8`      |
## | `-d:Pon2TsuGarbageRate=<int>`   | Garbage rate in Tsu rule.   | `70`     |
## | `-d:Pon2WaterGarbageRate=<int>` | Garbage rate in Water rule. | `90`     |
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ./[rule]

const
  Height* = 13
  Width* = 6
  Pon2WaterHeight {.intdefine.} = 8
  WaterHeight* = Pon2WaterHeight
  AirHeight* = Height - WaterHeight

  Pon2TsuGarbageRate {.intdefine.} = 70
  Pon2WaterGarbageRate {.intdefine.} = 90

static:
  doAssert WaterHeight >= 2 # height of a vertical pair
  doAssert AirHeight >= 3 # height of a vertical pair, and ghost
  doAssert Pon2TsuGarbageRate >= 1
  doAssert Pon2WaterGarbageRate >= 1

type
  Row* = range[0..Height.pred]
  Column* = range[0..Width.pred]
  WaterRow* = range[AirHeight..Height.pred]
  AirRow* = range[0..AirHeight.pred]

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
