## This module implements types and constants related to fields.
##
## Compile Options:
## | Option                      | Description          | Default |
## | --------------------------- | -------------------- | ------- |
## | `-d:pon2.waterheight=<int>` | Height of the water. | `8`     |
##

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
type
  Row* = range[0..Height.pred]
  Column* = range[0..Width.pred]
  WaterRow* = range[AirHeight..Height.pred]
  AirRow* = range[0..AirHeight.pred]
