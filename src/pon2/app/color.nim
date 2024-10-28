## This module implements colors.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

type Color* = object ## Color.
  red*: byte
  green*: byte
  blue*: byte
  alpha*: byte = 255

const
  SelectColor* = Color(red: 0, green: 209, blue: 178)
  GhostColor* = Color(red: 200, green: 200, blue: 200)
  WaterColor* = Color(red: 135, green: 248, blue: 255)
  DefaultColor* = Color(red: 225, green: 225, blue: 225)

# ------------------------------------------------
# Backend-specific
# ------------------------------------------------

when defined(js):
  import std/[strformat, strutils]
  import karax/[kbase]

  func toColorCode*(color: Color): kstring {.inline.} =
    ## Returns the color code (including '#') converted from the color.
    kstring &"#{color.red.toHex 2}{color.green.toHex 2}{color.blue.toHex 2}{color.alpha.toHex 2}"
else:
  import nigui

  func toNiguiColor*(color: Color): nigui.Color {.inline.} =
    ## Returns `nigui.Color` converted from the color.
    rgb(color.red, color.green, color.blue, color.alpha)
