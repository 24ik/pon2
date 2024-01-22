## This module implements the replay pagination control.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[options, strformat, sugar]
import nigui
import ../../../../apppkg/[editorpermuter, misc]

type ReplayPaginationControl* = ref object of LayoutContainer
  ## Replay pagination control.
  editorPermuter: ref EditorPermuter

proc initPrevNextHandler(control: ReplayPaginationControl, next: bool):
    (event: ClickEvent) -> void =
  ## Returns the click handler.
  # NOTE: inlining does not work due to lazy evaluation
  (event: ClickEvent) => (block:
    if next:
      control.editorPermuter[].nextReplay
    else:
      control.editorPermuter[].prevReplay)

proc drawHandler(control: ReplayPaginationControl): (event: DrawEvent) -> void =
  ## Draws the replay index.
  # NOTE: inlining does not work due to lazy evaluation
  proc handler(event: DrawEvent) =
    let canvas = event.control.canvas

    canvas.areaColor = DefaultColor.toNiguiColor
    canvas.fill

    let
      showIdx =
        if control.editorPermuter[].replayData.isNone: 0
        elif control.editorPermuter[].replayData.get.len == 0: 0
        else: control.editorPermuter[].replayIdx
      showLen =
        if control.editorPermuter[].replayData.isNone: 0
        else: control.editorPermuter[].replayData.get.len

    canvas.drawText &"{showIdx} / {showLen}"

  result = handler

proc initReplayPaginationControl*(editorPermuter: ref EditorPermuter):
    ReplayPaginationControl {.inline.} =
  ## Returns the replay pagination control.
  result = new ReplayPaginationControl
  result.init
  result.layout = Layout_Horizontal

  result.editorPermuter = editorPermuter

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
