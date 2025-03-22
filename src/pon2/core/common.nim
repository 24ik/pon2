## This module implements common constants.
##
## Compile Options:
## | Option                      | Description          | Default |
## | --------------------------- | -------------------- | ------- |
## | `-d:pon2.waterheight=<int>` | Height of the water. | `8`     |
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

const
  Height* = 13
  Width* = 6
  WaterHeight* {.define: "pon2.waterheight".} = 8
  AirHeight* = Height - WaterHeight

static:
  doAssert WaterHeight >= 2
  doAssert AirHeight >= 3
