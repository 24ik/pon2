## This module implements the requirement control.
##

import sugar

import nazopuyo_core
import nigui

import ./common
import ./state
import ../resource
import ../../setting/main
import ../../setting/theme

type RequirementControl* = ref object of ControlImpl
  ## Requirement control.
  nazo: ref Nazo

  mode: ref Mode
  focus: ref Focus

  setting: ref Setting

# ------------------------------------------------
# Property
# ------------------------------------------------

proc requirementControl(event: DrawEvent): RequirementControl {.inline.} =
  ## Returns the requirement control from the `event`.
  let control = event.control.parentWindow.control.childControls[0]
  assert control of RequirementControl
  return cast[RequirementControl](control)

# ------------------------------------------------
# Constructor
# ------------------------------------------------

proc requirementDrawHandler(event: DrawEvent) {.inline.} =
  ## Draws the requirement.
  let
    control = event.requirementControl
    theme = control.setting[].theme
    canvas = event.control.canvas

  canvas.areaColor =
    if control.mode[] == Mode.EDIT and control.focus[] == Focus.REQUIREMENT: theme.bgSelect
    else: theme.bgControl
  canvas.fill

  canvas.drawText $control.nazo[].req

proc newRequirementControl*(
  nazo: ref Nazo,

  mode: ref Mode,
  focus: ref Focus,

  setting: ref Setting,
  resource: ref Resource,
): RequirementControl {.inline.} =
  ## Returns a new requirement control.
  result = new RequirementControl
  result.init

  result.nazo = nazo
  result.mode = mode
  result.focus = focus
  result.setting = setting

  result.onDraw = (event: DrawEvent) => event.requirementDrawHandler

  # NOTE: width should be set in the root; cannot determine it here
  result.fontSize = resource[].cellImageHeight.pt
  result.height = resource[].cellImageHeight
