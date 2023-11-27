## This module implements the answer control.
##

import options
import strformat
import sugar

import nigui
import puyo_simulator

import ../common
import ../../core/manager/editor

type AnswerControl* = ref object of LayoutContainer
  ## Answer control.
  manager: ref EditorManager

proc answerIndexDrawHandler(control: AnswerControl, event: DrawEvent) {.inline.} =
  ## Draws the answer index.
  let canvas = event.control.canvas

  canvas.areaColor = DefaultColor
  canvas.fill

  canvas.drawText(
    if control.manager[].answers.isSome and control.manager[].answers.get.len > 0:
      &"{control.manager[].answerIdx} / {control.manager[].answers.get.len}"
    else: "0 / 0")

proc makeAnswerIndexDrawHandler(control: AnswerControl): (event: DrawEvent) -> void =
  ## Returns the index draw handler.
  # NOTE: inline handler does not work due to specifications
  (event: DrawEvent) => control.answerIndexDrawHandler(event)

proc answerClickHandler(control: AnswerControl, event: ClickEvent, next: bool) {.inline.} =
  ## Goes to the next/prev answers.
  if next:
    control.manager[].nextAnswer
  else:
    control.manager[].prevAnswer

proc makeAnswerClickHandler(control: AnswerControl, next: bool): (event: ClickEvent) -> void =
  ## Returns the click handler.
  # NOTE: inline handler does not work due to specifications
  (event: ClickEvent) => control.answerClickHandler(event, next)

proc newAnswerControl*(manager: ref EditorManager): AnswerControl {.inline.} =
  ## Returns a new answer control.
  result = new AnswerControl
  result.init
  result.layout = Layout_Vertical

  result.manager = manager

  # row=0
  let pageButtons = newLayoutContainer Layout_Horizontal
  result.add pageButtons

  let
    prevButton = newButton "前の解"
    answerIdxControl = newControl()
    nextButton = newButton "次の解"
  pageButtons.add prevButton
  pageButtons.add answerIdxControl
  pageButtons.add nextButton

  prevButton.onClick = result.makeAnswerClickHandler false
  answerIdxControl.onDraw = result.makeAnswerIndexDrawHandler
  nextButton.onClick = result.makeAnswerClickHandler true

  # row=1
  result.add manager[].answerSimulator.makePuyoSimulatorAnswerControl
