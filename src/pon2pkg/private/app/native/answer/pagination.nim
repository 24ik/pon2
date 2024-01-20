## This module implements the answer pagination control.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[options, strformat, sugar]
import nigui
import ../../../../apppkg/[editorpermuter, misc]

type AnswerPaginationControl* = ref object of LayoutContainer
  ## Answer pagination control.
  editorPermuter: ref EditorPermuter

proc initPrevNextHandler(control: AnswerPaginationControl, next: bool):
    (event: ClickEvent) -> void =
  ## Returns the click handler.
  # NOTE: inlining does not work due to lazy evaluation
  (event: ClickEvent) => (block:
    if next:
      control.editorPermuter[].nextAnswer
    else:
      control.editorPermuter[].prevAnswer)

proc drawHandler(control: AnswerPaginationControl): (event: DrawEvent) -> void =
  ## Draws the answer index.
  # NOTE: inlining does not work due to lazy evaluation
  proc handler(event: DrawEvent) =
    let canvas = event.control.canvas

    canvas.areaColor = DefaultColor.toNiguiColor
    canvas.fill

    let
      showIdx =
        if control.editorPermuter[].answers.isNone: 0
        elif control.editorPermuter[].answers.get.len == 0: 0
        else: control.editorPermuter[].answerIdx
      showLen =
        if control.editorPermuter[].answers.isNone: 0
        else: control.editorPermuter[].answers.get.len

    canvas.drawText &"{showIdx} / {showLen}"

  result = handler

proc initAnswerPaginationControl*(editorPermuter: ref EditorPermuter):
    AnswerPaginationControl {.inline.} =
  ## Returns the answer pagination control.
  result = new AnswerPaginationControl
  result.init
  result.layout = Layout_Horizontal

  result.editorPermuter = editorPermuter

  let
    prevButton = newButton "前の解"
    answerIdxControl = newControl()
    nextButton = newButton "次の解"
  result.add prevButton
  result.add answerIdxControl
  result.add nextButton

  prevButton.onClick = result.initPrevNextHandler false
  answerIdxControl.onDraw = result.drawHandler
  nextButton.onClick = result.initPrevNextHandler true
