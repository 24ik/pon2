{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/app/[color]

when defined(js):
  import std/[strformat, strutils]
  import karax/[kbase]
else:
  import nigui

proc main*() =
  # ------------------------------------------------
  # Backend-specific
  # ------------------------------------------------

  when defined(js):
    # toColorCode
    block:
      let c = WaterColor
      check c.toColorCode ==
        kstring &"#{c.red.toHex 2}{c.green.toHex 2}{c.blue.toHex 2}{c.alpha.toHex 2}"
  else:
    # toNiguiColor
    block:
      let c = WaterColor
      check c.toNiguiColor ==
        nigui.Color(red: c.red, green: c.green, blue: c.blue, alpha: c.alpha)
