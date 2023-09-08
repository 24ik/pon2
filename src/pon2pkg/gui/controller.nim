## This module implements the controller control.
##

import sugar

import nigui

import ./common
import ../manager

type ControllerControl* = ref object of LayoutContainer
  ## Solve control.
  manager: ref Manager

proc toggleHandler(control: ControllerControl, event: ClickEvent) {.inline.} =
  ## Toggles `manager.focusAnswer`.
  control.manager[].toggleFocus
  control.childControls[0].backgroundColor = if control.manager[].focusAnswer: SelectColor else: DefaultColor

proc makeToggleHandler(control: ControllerControl): (event: ClickEvent) -> void =
  ## Returns the toggler handler.
  # NOTE: inline handler does not work due to specifications
  (event: ClickEvent) => control.toggleHandler event

proc solveHandler(control: ControllerControl, event: ClickEvent) {.inline.} =
  ## Solves the nazo puyo.
  # TODO: async
  control.manager[].solve

proc makeSolveHandler(control: ControllerControl): (event: ClickEvent) -> void =
  ## Returns the solve handler.
  # NOTE: inline handler does not work due to specifications
  (event: ClickEvent) => control.solveHandler event

proc newControllerControl*(manager: ref Manager): ControllerControl {.inline.} =
  ## Returns a new controller control.
  result = new ControllerControl
  result.init
  result.layout = Layout_Horizontal

  result.manager = manager

  let
    toggleButton = newColorButton "解答を操作"
    solveButton = newButton "解探索"
    copyButton = newButton "Pon!通URLをコピー"
  result.add toggleButton
  result.add solveButton
  result.add copyButton

  toggleButton.onClick = result.makeToggleHandler
  solveButton.onClick = result.makeSolveHandler
  copyButton.onClick = (event: ClickEvent) => (app.clipboardText = $manager[].toUri)

  # set color
  toggleButton.backgroundColor = if manager[].focusAnswer: SelectColor else: DefaultColor
