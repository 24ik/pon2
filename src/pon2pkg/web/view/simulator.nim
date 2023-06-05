## This module implements the simulator frame.
##

import karax/vstyles
include karax/prelude

var simulatorUrl* = kstring""

proc simulatorFrame*: VNode =
  ## Returns the simulator frame.
  buildHtml(tdiv):
    if simulatorUrl.len > 0:
      iframe(
        src = simulatorUrl,
        width = "100%",
        height = "100%",
        scrolling = "no",
        style = style(StyleAttr.position, kstring"absolute"),
      )
