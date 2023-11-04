## This module implements miscellaneous things.
##

{.experimental: "strictDefs".}

const
  Height* = 13
  Width* = 6
  WaterHeight* {.intdefine.} = 8
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

  IzumiyaSimulatorKind* {.pure.} = enum
    ## Kind of the web simulator with izumiya format.
    Regular = "r"
    Nazo = "n"

  IzumiyaSimulatorMode* {.pure.} = enum
    ## Mode of the web simulator with izumiya format.
    Play = "p"
    Edit = "e"
    Replay = "r"

  IshikawaSimulatorMode* {.pure.} = enum
    ## Mode of the web simulator with ishikawa or ips format.
    Edit = "e"
    Simu = "s"
    View = "v"
    Nazo = "n"
