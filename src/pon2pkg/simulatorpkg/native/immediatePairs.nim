## This module implements the immediate pairs control.
##

{.experimental: "strictDefs".}

import std/[sugar]
import nigui
import ./[assets, misc]
import ../[simulator]
import ../../corepkg/[cell]
import ../../private/simulator/[render]

type ImmediatePairsControl* = ref object of LayoutContainer
  ## Immediate pairs control.
  simulator: ref Simulator
  assets: ref Assets

proc cellDrawHandler(control: ImmediatePairsControl, event: DrawEvent,
                     idx: Natural) {.inline.} =
  ## Draws the cell.
  let canvas = event.control.canvas

  canvas.areaColor = DefaultColor
  canvas.fill

  let cell = case idx
  of 0..2: Cell.None
  of 3: control.simulator[].immediateNextPairCell false
  of 4: control.simulator[].immediateNextPairCell true
  of 5: Cell.None
  of 6: control.simulator[].immediateDoubleNextPairCell false
  of 7: control.simulator[].immediateDoubleNextPairCell true
  else: Cell.None
  canvas.drawImage control.assets[].cellImages[cell]

func initCellDrawHandler(control: ImmediatePairsControl, idx: Natural):
    (event: DrawEvent) -> void =
  ## Returns the draw handler.
  # NOTE: inline handler does not work due to specifications
  (event: DrawEvent) => control.cellDrawHandler(event, idx)

proc initImmediatePairsControl*(simulator: ref Simulator, assets: ref Assets):
    ImmediatePairsControl {.inline.} =
  ## Returns an immediate pairs control.
  result = new ImmediatePairsControl
  result.init
  result.layout = Layout_Vertical

  result.simulator = simulator
  result.assets = assets

  result.spacing = 0
  result.padding = 0

  for idx in 0..7:
    let cell = newControl()
    result.add cell

    cell.height = assets[].cellImageSize.height
    cell.width = assets[].cellImageSize.width
    cell.onDraw = result.initCellDrawHandler idx
