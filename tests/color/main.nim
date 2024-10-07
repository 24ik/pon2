{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/app/[color]

when defined(js):
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
      check WaterColor.toColorCode == "#87CEFAFF"
  else:
    # toNiguiColor
    block:
      check WaterColor.toNiguiColor ==
        nigui.Color(
          red: WaterColor.red,
          green: WaterColor.green,
          blue: WaterColor.blue,
          alpha: WaterColor.alpha,
        )
