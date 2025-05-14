## This module implements colors.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

when defined(js):
  import std/[strformat]
  import ../private/[strutils2]

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

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js):
  func code*(color: Color): cstring {.inline.} =
    ## Returns the color code (including '#') converted from the color.
    "#{color.red.toHex 2}{color.green.toHex 2}{color.blue.toHex 2}{color.alpha.toHex 2}".fmt.toLowerAscii.cstring
