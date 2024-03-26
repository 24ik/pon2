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
      control.guiApplication[].nextReplay
    else:
      control.guiApplication[].prevReplay

  result = handler

proc initDrawHandler(control: EditorPaginationControl): (event: DrawEvent) -> void =
  ## Draws the replay index.
  # NOTE: inlining does not work due to lazy evaluation
  proc handler(event: DrawEvent) =
    let canvas = event.control.canvas

    canvas.areaColor = DefaultColor.toNiguiColor
    canvas.fill

    let
      showIdx =
        if not control.guiApplication[].replay.hasData:
          0
        elif control.guiApplication[].replay.pairsPositionsSeq.len == 0:
          0
        else:
          control.guiApplication[].replay.index
      showLen =
        if not control.guiApplication[].replay.hasData:
          0
        else:
          control.guiApplication[].replay.pairsPositionsSeq.len

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
    replayIdxControl = newControl()
    nextButton = newButton "次の解"
  result.add prevButton
  result.add replayIdxControl
  result.add nextButton

  prevButton.onClick = result.initPrevNextHandler false
  replayIdxControl.onDraw = result.initDrawHandler
  nextButton.onClick = result.initPrevNextHandler true
