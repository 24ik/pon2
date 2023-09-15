## This module implements the controller control.
##

import options
import sugar
import threadpool

import nazopuyo_core
import nigui
import puyo_simulator

import ../common
import ../../core/manager/editor
import ../../core/solve

type ControllerControl* = ref object of LayoutContainer
  ## Solve control.
  manager: ref EditorManager

proc toggleHandler(control: ControllerControl, event: ClickEvent) {.inline.} =
  ## Toggles `manager.focusAnswer`.
  control.manager[].toggleFocus
  control.childControls[0].backgroundColor = if control.manager[].focusAnswer: SelectColor else: DefaultColor

proc makeToggleHandler(control: ControllerControl): (event: ClickEvent) -> void =
  ## Returns the toggler handler.
  # NOTE: inline handler does not work due to specifications
  (event: ClickEvent) => control.toggleHandler event

var globalControl: ControllerControl = nil # FIXME: remove global control

proc solveWrite(nazo: NazoPuyo) {.inline.} =
  ## Solves the nazo puyo and write answers.
  let answers = nazo.solve
  {.gcsafe.}:
    app.queueMain () => (
      globalControl.manager[].answers = some answers;
      globalControl.manager[].updateAnswerSimulator nazo;

      globalControl.manager[].solving = false;

      globalControl.parentWindow.control.forceRedraw)

proc solve*(manager: var EditorManager) {.inline.} =
  ## Solves the nazo puyo.
  if manager.solving or manager.simulator[].requirement.isNone:
    return

  manager.solving = true

  spawn manager.simulator[].nazoPuyo.get.solveWrite

proc makeSolveHandler(control: ControllerControl): (event: ClickEvent) -> void =
  ## Returns the solve handler.
  # NOTE: inline handler does not work due to specifications
  (event: ClickEvent) => control.manager[].solve

proc newControllerControl*(manager: ref EditorManager): ControllerControl {.inline.} =
  ## Returns a new controller control.
  result = new ControllerControl
  result.init
  result.layout = Layout_Horizontal

  doAssert globalControl.isNil
  globalControl = result

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
