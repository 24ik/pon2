## This module implements the editor controller node.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import karax/[karax, karaxdsl, kbase, vdom]
import ./[settings]
import ../../[misc]
import ../../../../app/[gui, nazopuyo, simulator]
import ../../../../core/[nazopuyo]

proc initEditorControllerNode*(
    guiApplication: ref GuiApplication, id = ""
): VNode {.inline.} =
  ## Returns the editor controller node.
  ## `id` is shared with other node-creating procedures and need to be unique.
  let
    workerRunning = guiApplication[].solving or guiApplication[].permuting
    noPair = guiApplication[].simulator.nazoPuyoWrap.get:
      wrappedNazoPuyo.puyoPuyo.pairsPositions.len == 0
    workerDisable = workerRunning or noPair

    focusButtonClass =
      if guiApplication[].focusReplay:
        kstring"button is-selected is-primary"
      else:
        kstring"button"
    solveButtonClass =
      if guiApplication[].solving:
        kstring"button is-loading"
      else:
        kstring"button"
    permuteButtonClass =
      if guiApplication[].permuting:
        kstring"button is-loading"
      else:
        kstring"button"

  proc permuteHandler() =
    let (_, fixMoves, allowDouble, allowLastDouble) = guiApplication[].simulator.nazoPuyoWrap.get:
      getSettings(id, wrappedNazoPuyo.moveCount)
    guiApplication[].permute fixMoves, allowDouble, allowLastDouble

  result = buildHtml(tdiv(class = "buttons")):
    button(
      class = solveButtonClass,
      disabled = workerDisable,
      onclick = () => (guiApplication[].solve getSettings(id, 1).parallelCount),
    ):
      text "解探索"
    button(
      class = permuteButtonClass, disabled = workerDisable, onclick = permuteHandler
    ):
      text "ツモ並べ替え"
    if not isMobile():
      button(class = focusButtonClass, onclick = () => guiApplication[].toggleFocus):
        text "解答を操作"
