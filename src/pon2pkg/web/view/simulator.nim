## This module implements the simulator frame.
##

import karax/vstyles
include karax/prelude

var
  simulatorUrls* = newSeq[kstring](0)
  simulatorIdx* = 0.Natural

proc goPrev =
  ## Shows the previous URL.
  if simulatorUrls.len == 0:
    return

  if simulatorIdx == 0:
    simulatorIdx = simulatorUrls.len.pred
  else:
    simulatorIdx.dec

proc goNext =
  ## Shows the next URL.
  if simulatorUrls.len == 0:
    return

  if simulatorIdx == simulatorUrls.len.pred:
    simulatorIdx = 0
  else:
    simulatorIdx.inc
  
proc simulatorFrame*: VNode =
  ## Returns the simulator frame.
  buildHtml(tdiv):
    tdiv:
      nav(class = "pagination", role = "navigation", aria_label = "pagination"):
        button(class = "button pagination-previous", onclick = goPrev): text "前の解"
        button(class = "button pagination-next", onclick = goNext): text "次の解"
    tdiv:
      if simulatorUrls.len > 0:
        iframe(
          src = simulatorUrls[simulatorIdx],
          width = "100%",
          height = "100%",
          scrolling = "no",
          style = style(StyleAttr.position, kstring"absolute"))
