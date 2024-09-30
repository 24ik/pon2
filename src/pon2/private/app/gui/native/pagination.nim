## This module implements the editor pagination control.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, sugar]
import nigui
import ../../../../app/[color, gui]

type EditorPaginationControl* = ref object of LayoutContainer
  ## Editor pagination control.
  guiApplication: ref GuiApplication

func initPrevNextHandler(
    control: EditorPaginationControl, next: bool
): (event: ClickEvent) -> void =
  ## Returns the click handler.
  # NOTE: inlining does not work due to lazy evaluation
  proc handler(event: ClickEvent) =
    if next:
      control.guiApplication[].nextAnswer
    else:
      control.guiApplication[].prevAnswer

  result = handler

proc initDrawHandler(control: EditorPaginationControl): (event: DrawEvent) -> void =
  ## Draws the answer index.
  # NOTE: inlining does not work due to lazy evaluation
  proc handler(event: DrawEvent) =
    let canvas = event.control.canvas

    canvas.areaColor = DefaultColor.toNiguiColor
    canvas.fill

    let
      showIdx =
        if not control.guiApplication[].answer.hasData:
          0
        elif control.guiApplication[].answer.pairsPositionsSeq.len == 0:
          0
        else:
          control.guiApplication[].answer.index
      showLen =
        if not control.guiApplication[].answer.hasData:
          0
        else:
          control.guiApplication[].answer.pairsPositionsSeq.len

    canvas.drawText &"{showIdx} / {showLen}"

  result = handler

proc initEditorPaginationControl*(
    guiApplication: ref GuiApplication
): EditorPaginationControl {.inline.} =
  ## Returns the editor pagination control.
  result = new EditorPaginationControl
  result.init
  result.layout = Layout_Horizontal

  result.guiApplication = guiApplication

  let
    prevButton = newButton "前の解"
    answerIdxControl = newControl()
    nextButton = newButton "次の解"
  result.add prevButton
  result.add answerIdxControl
  result.add nextButton

  prevButton.onClick = result.initPrevNextHandler false
  answerIdxControl.onDraw = result.initDrawHandler
  nextButton.onClick = result.initPrevNextHandler true
