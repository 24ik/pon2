## This module implements the editor controller node.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import karax/[karax, karaxdsl, kbase, vdom]
import ./[settings]
import ../../../../../apppkg/[editorpermuter, simulator]
import ../../../../../corepkg/[pair]
import ../../../../../nazopuyopkg/[nazopuyo]

proc initEditorControllerNode*(editorPermuter: var EditorPermuter, id = ""):
    VNode {.inline.} =
  ## Returns the editor controller node.
  let
    workerRunning = editorPermuter.solving or editorPermuter.permuting
    workerDisable = workerRunning or editorPermuter.simulator[].pairs.len == 0

    focusButtonClass =
      if editorPermuter.focusEditor: kstring"button"
      else: kstring"button is-selected is-primary"
    solveButtonClass =
      if editorPermuter.solving: kstring"button is-loading"
      else: kstring"button"
    permuteButtonClass =
      if editorPermuter.permuting: kstring"button is-loading"
      else: kstring"button"

  proc permuteHandler =
    editorPermuter.simulator[].withNazoPuyo:
      let (_, fixMoves, allowDouble, allowLastDouble) = getSettings(
        id, nazoPuyo.moveCount)
      editorPermuter.permute fixMoves, allowDouble, allowLastDouble

  result = buildHtml(tdiv(class = "buttons")):
    button(class = solveButtonClass, disabled = workerDisable,
           onclick = () => (
            editorPermuter.solve getSettings(id, 1).parallelCount)):
      text "解探索"
    button(class = permuteButtonClass, disabled = workerDisable,
           onclick = permuteHandler):
      text "ツモ並べ替え"
    button(class = focusButtonClass,
           onclick = () => editorPermuter.toggleFocus):
      text "シミュを操作"
