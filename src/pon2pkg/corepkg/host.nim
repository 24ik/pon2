## This module implements simulator's hosts.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

type SimulatorHost* {.pure.} = enum
  ## URI host of the web simulator.
  Izumiya = "izumiya-keisuke.github.io"
  Ishikawa = "ishikawapuyo.net"
  Ips = "ips.karou.jp"
