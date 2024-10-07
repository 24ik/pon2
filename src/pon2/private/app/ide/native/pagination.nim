## This module implements the editor pagination control.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, sugar]
import nigui
import ../../../../app/[color, ide]

type EditorPaginationControl* = ref object of LayoutContainer not nil
  ## Editor pagination control.
  ide: Ide

func newPrevNextHandler(
    control: EditorPaginationControl, next: bool
): (event: ClickEvent) -> void =
  ## Returns the click handler.
  # NOTE: inlining does not work due to lazy evaluation
  proc handler(event: ClickEvent) =
    if next:
      control.ide.nextAnswer
    else:
      control.ide.prevAnswer

  result = handler

proc newDrawHandler(control: EditorPaginationControl): (event: DrawEvent) -> void =
  ## Draws the answer index.
  # NOTE: inlining does not work due to lazy evaluation
  proc handler(event: DrawEvent) =
    let canvas = event.control.canvas

    canvas.areaColor = DefaultColor.toNiguiColor
    canvas.fill

    let
      showIdx =
        if not control.ide.answerData.hasData:
          0
        elif control.ide.answerData.pairsPositionsSeq.len == 0:
          0
        else:
          control.ide.answerData.index
      showLen =
        if not control.ide.answerData.hasData:
          0
        else:
          control.ide.answerData.pairsPositionsSeq.len

    canvas.drawText &"{showIdx} / {showLen}"

  result = handler

proc newEditorPaginationControl*(
    ide: Ide
): EditorPaginationControl {.inline.} =
  ## Returns the editor pagination control.
  {.push warning[ProveInit]: off.}
  result.new
  {.pop.}
  result.init
  result.layout = Layout_Horizontal

  result.ide = ide

  let
    prevButton = newButton "前の解"
    answerIdxControl = newControl()
    nextButton = newButton "次の解"
  result.add prevButton
  result.add answerIdxControl
  result.add nextButton

  prevButton.onClick = result.newPrevNextHandler false
  answerIdxControl.onDraw = result.newDrawHandler
  nextButton.onClick = result.newPrevNextHandler true
