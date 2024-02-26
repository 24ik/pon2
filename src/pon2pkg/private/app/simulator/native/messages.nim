## This module implements the messages control.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import nigui
import ./[assets]
import ../[common]
import ../../../../app/[color, simulator]
import ../../../../core/[misc]

type MessagesControl* = ref object of ControlImpl ## Messages control.
  simulator: ref Simulator

# ------------------------------------------------
# Control
# ------------------------------------------------

proc messagesDrawHandler(control: MessagesControl, event: DrawEvent) {.inline.} =
  ## Draws the message.
  let canvas = event.control.canvas

  canvas.areaColor = DefaultColor.toNiguiColor
  canvas.fill

  if control.simulator[].mode != Edit:
    canvas.drawText control.simulator[].getMessages.state

func initMessageDrawHandler(control: MessagesControl): (event: DrawEvent) -> void =
  ## Returns the handler.
  # NOTE: cannot inline due to lazy evaluation
  (event: DrawEvent) => control.messagesDrawHandler event

proc initMessagesControl*(
    simulator: ref Simulator, assets: ref Assets
): MessagesControl {.inline.} =
  ## Returns a messages control.
  result = new MessagesControl
  result.init

  result.simulator = simulator

  result.height = assets[].cellImageSize.height
  result.fontSize = result.height.pt
  result.onDraw = result.initMessageDrawHandler

# ------------------------------------------------
# API
# ------------------------------------------------

proc setWidth*(control: MessagesControl, width: Natural) {.inline.} =
  ## Sets the width.
  control.width = width
