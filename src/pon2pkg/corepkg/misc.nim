## This module implements miscellaneous things.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

type
  SimulatorKind* {.pure.} = enum
    ## Kind of the web simulator.
    Regular = "r"
    Nazo = "n"

  SimulatorMode* {.pure.} = enum
    ## Mode of the web simulator.
    Edit = "e"
    Play = "p"
    Replay = "r"
