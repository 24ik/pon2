## This module implements common stuff.
##

import nigui

# ------------------------------------------------
# Button
# ------------------------------------------------

type ColorButton* = ref object of Button ## [Reference](https://github.com/simonkrauter/NiGui/issues/9)

proc newColorButton*(text = ""): ColorButton {.inline.} =
  ## Returns a new color button.
  result = new ColorButton
  result.init
  result.text = text

method handleDrawEvent*(control: ColorButton, event: DrawEvent) =
  let canvas = event.control.canvas
  canvas.areaColor = control.backgroundColor
  canvas.textColor = control.textColor
  canvas.lineColor = control.textColor
  canvas.drawRectArea(0, 0, control.width, control.height)
  canvas.drawTextCentered(control.text)
  canvas.drawRectOutline(0, 0, control.width, control.height)

# ------------------------------------------------
# Color
# ------------------------------------------------

const
  DefaultColor* = rgb(255, 255, 255)
  SelectColor* = rgb(0, 209, 178)
