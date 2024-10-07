## This module implements the editor controller node.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import karax/[karax, karaxdsl, kbase, vdom]
import ./[settings]
import ../../[misc]
import ../../../../app/[ide, nazopuyo, simulator]
import ../../../../core/[nazopuyo]

proc newEditorControllerNode*(ide: Ide, settingsId: string): VNode {.inline.} =
  ## Returns the editor controller node.
  let
    workerRunning = ide.solving or ide.permuting
    noPair = ide.simulator[].nazoPuyoWrap.get:
      wrappedNazoPuyo.puyoPuyo.pairsPositions.len == 0
    workerDisable = workerRunning or noPair

    focusButtonClass =
      if ide.focusAnswer:
        kstring"button is-selected is-primary"
      else:
        kstring"button"
    solveButtonClass =
      if ide.solving:
        kstring"button is-loading"
      else:
        kstring"button"
    permuteButtonClass =
      if ide.permuting:
        kstring"button is-loading"
      else:
        kstring"button"

  proc permuteHandler() =
    let (_, fixMoves, allowDouble, allowLastDouble) = ide.simulator[].nazoPuyoWrap.get:
      getSettings(settingsId, wrappedNazoPuyo.moveCount)
    ide.permute fixMoves, allowDouble, allowLastDouble

  result = buildHtml(tdiv(class = "buttons")):
    button(
      class = solveButtonClass,
      disabled = workerDisable,
      onclick = () => (ide.solve getSettings(settingsId, 1).parallelCount),
    ):
      text "解探索"
    button(
      class = permuteButtonClass, disabled = workerDisable, onclick = permuteHandler
    ):
      text "ツモ並べ替え"
    if not isMobile():
      button(class = focusButtonClass, onclick = () => ide.toggleFocus):
        text "解答を操作"
