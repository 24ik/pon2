## This module implements the first pair control.
##

import deques
import sugar

import nazopuyo_core
import nigui
import puyo_core

import ./state
import ../resource
import ../../setting/main
import ../../setting/theme

type FirstPairControl* = ref object of LayoutContainer
  ## First pair control.
  nazo: ref Nazo

  mode: ref Mode
  state: ref SimulatorState
  nextIdx: ref Natural
  nextPos: ref Position

  setting: ref Setting
  resource: ref Resource

# ------------------------------------------------
# Property
# ------------------------------------------------

proc firstPairControl(event: DrawEvent): FirstPairControl {.inline.} =
  ## Returns the first pair control from the `event`.
  let control = event.control.parentWindow.control.childControls[1].childControls[0].childControls[0]
  assert control of FirstPairControl
  return cast[FirstPairControl](control)

# ------------------------------------------------
# Constructor
# ------------------------------------------------

proc cellDrawHandler(event: DrawEvent, rowDiff: int, col: Col) {.inline.} =
  ## Draws cells in the first pair.
  let
    control = event.firstPairControl
    theme = control.setting[].theme
    canvas = event.control.canvas

  canvas.areaColor = theme.bgControl
  canvas.fill

  const
    DirToColDiff: array[Direction, int] = [UP: 0, RIGHT: 1, DOWN: 0, LEFT: -1]
    DirToRowDiff: array[Direction, int] = [UP: -1, RIGHT: 0, DOWN: 1, LEFT: 0]
  let
    pos = if control.mode[] == Mode.PLAY: control.nextPos[] else: POS_3U
    cell =
      if control.nextIdx[] >= control.nazo[].env.pairs.len: NONE
      elif control.state[] != MOVING: NONE
      elif col == pos.axisCol and rowDiff == 0: control.nazo[].env.pairs[control.nextIdx[]].axis
      elif col == (pos.axisCol.int.succ DirToColDiff[pos.childDir]) and rowDiff == DirToRowDiff[pos.childDir]:
        control.nazo[].env.pairs[control.nextIdx[]].child
      else: NONE
  canvas.drawImage control.resource[].cellImages[cell]

proc newCellControl(rowDiff: int, col: Col): Control {.inline.} =
  ## Returns a cell control.
  result = newControl()
  result.onDraw = (event: DrawEvent) => event.cellDrawHandler(rowDiff, col)

proc newFirstPairControl*(
  nazo: ref Nazo,

  mode: ref Mode,
  state: ref SimulatorState,
  nextIdx: ref Natural,
  nextPos: ref Position,

  setting: ref Setting,
  resource: ref Resource,
): FirstPairControl {.inline.} =
  ## Returns a new first pair control.
  result = new FirstPairControl
  result.init
  result.layout = Layout_Vertical

  result.nazo = nazo
  result.mode = mode
  result.state = state
  result.nextIdx = nextIdx
  result.nextPos = nextPos
  result.setting = setting
  result.resource = resource

  for rowDiff in -1 .. 1:
    let line = newLayoutContainer Layout_Horizontal
    line.spacing = 0
    line.padding = 0

    for col in Col.low .. Col.high:
      let cell = newCellControl(rowDiff, col)
      cell.width = resource[].cellImageWidth
      cell.height = resource[].cellImageHeight
      line.add cell

    result.add line
