## This module implements the pairs control.
##

import std/[sugar]
import nigui
import ./[assets, misc]
import ../[simulator, render]
import ../../core/[cell, pair, position]

type PairsControl* = ref object of LayoutContainer
  ## Pairs control.
  simulator: ref Simulator
  assets: ref Assets

# ------------------------------------------------
# Pair
# ------------------------------------------------

proc cellDrawHandler(control: PairsControl, event: DrawEvent, idx: Natural,
                     isAxis: bool) {.inline.} =
  ## Draws the cell.
  let canvas = event.control.canvas

  canvas.areaColor =
    if control.simulator[].pairCellSelected(idx, isAxis): SelectColor
    else: DefaultColor
  canvas.fill

  var cell = None
  if idx < control.simulator[].originalPairs.len:
    let pair = control.simulator[].originalPairs[idx]
    cell = if isAxis: pair.axis else: pair.child
  canvas.drawImage control.assets[].cellImages[cell]

func initCellDrawHandler(control: PairsControl, idx: Natural, isAxis: bool):
    (event: DrawEvent) -> void =
  ## Returns the pair's draw handler.
  # NOTE: inline handler does not work due to specifications
  (event: DrawEvent) => control.cellDrawHandler(event, idx, isAxis)

proc initPairControl(control: PairsControl, idx: Natural, assets: ref Assets):
    LayoutContainer {.inline.} =
  ## Returns a pair control.
  result = newLayoutContainer Layout_Horizontal

  result.spacing = 0
  result.padding = 0

  let
    axis = newControl()
    child = newControl()
  result.add axis
  result.add child

  axis.height = assets[].cellImageSize.height
  axis.width = assets[].cellImageSize.width
  axis.onDraw = control.initCellDrawHandler(idx, true)

  child.height = assets[].cellImageSize.height
  child.width = assets[].cellImageSize.width
  child.onDraw = control.initCellDrawHandler(idx, false)

# ------------------------------------------------
# Index
# ------------------------------------------------

proc indexDrawHandler(control: PairsControl, event: DrawEvent, idx: Natural)
                     {.inline.} =
  ## Draws the index.
  let canvas = event.control.canvas

  canvas.areaColor = DefaultColor
  canvas.fill

  let nextArrow = if control.simulator[].pairSelected(idx): "> " else: "  "
  canvas.drawText nextArrow & $idx.succ

func initIndexDrawHandler(control: PairsControl, idx: Natural):
    (event: DrawEvent) -> void =
  ## Returns the index's draw handler.
  # NOTE: inline handler does not work due to specifications
  (event: DrawEvent) => control.indexDrawHandler(event, idx)

proc initIndexControl(control: PairsControl, idx: Natural): Control {.inline.} =
  ## Returns an index control.
  result = newControl()
  result.onDraw = control.initIndexDrawHandler idx

# ------------------------------------------------
# Position
# ------------------------------------------------

proc positionDrawHandler(control: PairsControl, event: DrawEvent, idx: Natural)
                        {.inline.} =
  ## Draws the position.
  let canvas = event.control.canvas

  canvas.areaColor = DefaultColor
  canvas.fill

  canvas.drawText if idx < control.simulator[].positions.len:
    $control.simulator[].positions[idx] else: "  "

func initPositionDrawHandler(control: PairsControl, idx: Natural):
    (event: DrawEvent) -> void =
  ## Returns the position's draw handler.
  # NOTE: inline handler does not work due to specifications
  (event: DrawEvent) => control.positionDrawHandler(event, idx)

proc initPositionControl(control: PairsControl, idx: Natural): Control
                        {.inline.} =
  ## Returns a position control.
  result = newControl()
  result.onDraw = control.initPositionDrawHandler idx

# ------------------------------------------------
# Pairs
# ------------------------------------------------

proc initFullPairControl(control: PairsControl, idx: Natural,
                         assets: ref Assets): LayoutContainer {.inline.} =
  ## Returns a full pair control.
  result = newLayoutContainer Layout_Horizontal

  let
    idxControl = control.initIndexControl idx
    pairControl = control.initPairControl(idx, assets)
    positionControl = control.initPositionControl idx
  result.add idxControl
  result.add pairControl
  result.add positionControl

  idxControl.fontSize = pairControl.naturalHeight.pt
  idxControl.width = idxControl.getTextWidth "> 99"
  idxControl.height = pairControl.naturalHeight

  positionControl.fontSize = pairControl.naturalHeight.pt
  positionControl.width = positionControl.getTextWidth $Position.low
  positionControl.height = pairControl.naturalHeight

proc initPairsControl*(simulator: ref Simulator, assets: ref Assets):
    PairsControl {.inline.} =
  ## Returns a pairs control.
  result = new PairsControl
  result.init
  result.layout = Layout_Vertical

  result.simulator = simulator
  result.assets = assets

  for idx in 0..simulator[].pairs.len:
    result.add result.initFullPairControl(idx, assets)
