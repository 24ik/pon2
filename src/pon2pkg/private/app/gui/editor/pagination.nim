## This module implements the editor pagination control.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[options, strformat, sugar]
import nigui
import ../../../../app/[color, gui]
import ../../../../core/[pairposition]

type EditorPaginationControl* = ref object of LayoutContainer
  ## Editor pagination control.
  guiApplication: ref GuiApplication

proc initPrevNextHandler(
    control: EditorPaginationControl, next: bool
): (event: ClickEvent) -> void =
  ## Returns the click handler.
  # NOTE: inlining does not work due to lazy evaluation
  (event: ClickEvent) => (
    block:
      if next:
        control.guiApplication[].nextReplay
      else:
        control.guiApplication[].prevReplay
  )

proc drawHandler(control: EditorPaginationControl): (event: DrawEvent) -> void =
  ## Draws the replay index.
  # NOTE: inlining does not work due to lazy evaluation
  proc handler(event: DrawEvent) =
    let canvas = event.control.canvas

    canvas.areaColor = DefaultColor.toNiguiColor
    canvas.fill

    let
      showIdx =
        if control.guiApplication[].replayPairsPositions.isNone:
          0
        elif control.guiApplication[].replayPairsPositions.get.len == 0:
          0
        else:
          control.guiApplication[].replayIdx
      showLen =
        if control.guiApplication[].replayPairsPositions.isNone:
          0
        else:
          control.guiApplication[].replayPairsPositions.get.len

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
  replayIdxControl.onDraw = result.drawHandler
  nextButton.onClick = result.initPrevNextHandler true
