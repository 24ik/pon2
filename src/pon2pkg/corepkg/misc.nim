## This module implements miscellaneous things.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

const
  Height* = 13
  Width* = 6
  Pon2WaterHeight {.intdefine.} = 8
  WaterHeight* = Pon2WaterHeight
  AirHeight* = Height - WaterHeight

static:
  doAssert WaterHeight >= 2 # height of a vertical pair
  doAssert AirHeight >= 3 # height of a vertical pair, and ghost

type
  Row* = range[0..Height.pred]
  Column* = range[0..Width.pred]
  WaterRow* = range[AirHeight..Height.pred]
  AirRow* = range[0..AirHeight.pred]

  Rule* {.pure.} = enum
    ## Puyo Puyo rule.
    Tsu = "t"
    Water = "w"

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
