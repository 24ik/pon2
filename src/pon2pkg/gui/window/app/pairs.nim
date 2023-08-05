## This module implements the pairs control.
##

import deques
import options
import sugar

import nazopuyo_core
import nigui
import puyo_core

import ./common
import ./state
import ../resource
import ../../setting/main
import ../../setting/theme

type PairsControl* = ref object of LayoutContainer
  ## Pairs control.
  nazo: ref Nazo
  positions: ref Positions

  mode: ref Mode
  focus: ref Focus
  inserted: ref bool
  nextIdx: ref Natural

  setting: ref Setting
  resource: ref Resource

  cursor*: tuple[idx: Natural, axis: bool]

# ------------------------------------------------
# Property
# ------------------------------------------------

proc pairsControl(event: DrawEvent): PairsControl {.inline.} =
  ## Returns the pairs control from the `event`.
  let control = event.control.parentWindow.control.childControls[1].childControls[1]
  assert control of PairsControl
  return cast[PairsControl](control)

# ------------------------------------------------
# Pair Constructor
# ------------------------------------------------

proc cellDrawHandler(event: DrawEvent, idx: Natural, axis: bool) {.inline.} =
  ## Draws cells in the pairs.
  let
    control = event.pairsControl
    theme = control.setting[].theme
    canvas = event.control.canvas

  canvas.areaColor =
    if control.mode[] == Mode.EDIT and control.focus[] == Focus.PAIRS and control.cursor == (idx, axis): theme.bgSelect
    else: theme.bgControl
  if control.inserted[]:
    let halfHeight = control.resource[].cellImageHeight div 2

    # upper half
    canvas.drawRectArea 0, 0, control.resource[].cellImageWidth, halfHeight

    # lower half
    canvas.areaColor = theme.bgControl
    canvas.drawRectArea 0, halfHeight, control.resource[].cellImageWidth, halfHeight
  else:
    canvas.fill

  if idx < control.nazo[].env.pairs.len:
    let pair = control.nazo[].env.pairs[idx]
    canvas.drawImage control.resource[].cellImages[if axis: pair.axis else: pair.child]

proc newCellControl(idx: Natural, axis: bool): Control {.inline.} =
  ## Returns a new cell control.
  result = newControl()
  result.onDraw = (event: DrawEvent) => event.cellDrawHandler(idx, axis)

proc newPairControl(idx: Natural, imgWidth: int, imgHeight: int): LayoutContainer {.inline.} =
  ## Returns a new pair control.
  result = newLayoutContainer Layout_Horizontal
  result.spacing = 0
  result.padding = 0

  let
    axis = idx.newCellControl true
    child = idx.newCellControl false
  axis.width = imgWidth
  axis.height = imgHeight
  child.width = imgWidth
  child.height = imgHeight

  result.add axis
  result.add child

# ------------------------------------------------
# Index Constructor
# ------------------------------------------------

proc idxDrawHandler(event: DrawEvent, idx: Natural) {.inline.} =
  ## Draws the index of the pairs.
  let
    control = event.pairsControl
    theme = control.setting[].theme
    canvas = event.control.canvas

  canvas.areaColor = theme.bgControl
  canvas.fill

  if idx < control.nazo[].env.pairs.len:
    let nextArrow = if control.nextIdx[] == idx: "> " else: "  "
    canvas.drawText nextArrow & $idx.succ

proc newIdxControl(idx: Natural): Control {.inline.} =
  ## Returns a new index control.
  result = newControl()
  result.onDraw = (event: DrawEvent) => event.idxDrawHandler idx

# ------------------------------------------------
# Position Constructor
# ------------------------------------------------

proc positionDrawHandler(event: DrawEvent, idx: Natural) {.inline.} =
  ## Draws the position of the pairs.
  let
    control = event.pairsControl
    theme = control.setting[].theme
    canvas = event.control.canvas

  canvas.areaColor = theme.bgControl
  canvas.fill

  if idx < control.nazo[].env.pairs.len:
    assert idx < control.positions[].len
    if control.positions[][idx].isSome:
      canvas.drawText $control.positions[][idx].get

proc newPositionControl(idx: Natural): Control {.inline.} =
  ## Returns a new position control.
  result = newControl()
  result.onDraw = (event: DrawEvent) => event.positionDrawHandler idx

# ------------------------------------------------
# Pairs Operation
# ------------------------------------------------

proc newPairWithInfoControl(idx: Natural, imgWidth: int, imgHeight: int): LayoutContainer {.inline.} =
  ## Returns a new full pair control.
  result = newLayoutContainer Layout_Horizontal

  let
    idxControl = idx.newIdxControl
    pairControl = idx.newPairControl(imgWidth, imgHeight)
    positionControl = idx.newPositionControl

  result.add idxControl
  result.add pairControl
  result.add positionControl

  idxControl.fontSize = pairControl.naturalHeight.pt
  idxControl.width = idxControl.getTextWidth "> 99"
  idxControl.height = pairControl.naturalHeight

  positionControl.fontSize = pairControl.naturalHeight.pt
  positionControl.width = positionControl.getTextWidth $POS_1U
  positionControl.height = pairControl.naturalHeight

proc addPairWithInfoControl*(control: PairsControl) {.inline.} =
  ## Adds a new full pair control to the `control`.
  control.add control.childControls.len.newPairWithInfoControl(
    control.resource[].cellImageWidth, control.resource[].cellImageHeight)

proc removePairWithInfoControl*(control: PairsControl) {.inline.} =
  ## Removes the last full pair control from the `control`.
  control.remove control.childControls[^1]

# ------------------------------------------------
# Pairs Constructor
# ------------------------------------------------

proc newPairsControl*(
  nazo: ref Nazo,
  positions: ref Positions,

  mode: ref Mode,
  focus: ref Focus,
  inserted: ref bool,
  nextIdx: ref Natural,

  setting: ref Setting,
  resource: ref Resource,

  cursor = (idx: 0.Natural, axis: true),
): PairsControl {.inline.} =
  ## Returns a new pairs control.
  result = new PairsControl
  result.init
  result.layout = Layout_Vertical

  result.nazo = nazo
  result.positions = positions
  result.mode = mode
  result.focus = focus
  result.inserted = inserted
  result.nextIdx = nextIdx
  result.setting = setting
  result.resource = resource
  result.cursor = cursor

  for _ in 0 .. nazo[].env.pairs.len:
    result.addPairWithInfoControl
