## This module implements colors.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

type Color* = object ## Color.
  red*: int
  green*: int
  blue*: int
  alpha*: int

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type Color, red, green, blue: int, alpha = 255): T {.inline.} =
  T(red: red, green: green, blue: blue, alpha: alpha)

const
  SelectColor* = Color.init(0, 209, 178)
  GhostColor* = Color.init(200, 200, 200)
  WaterColor* = Color.init(135, 248, 255)
  DefaultColor* = Color.init(225, 225, 225)
