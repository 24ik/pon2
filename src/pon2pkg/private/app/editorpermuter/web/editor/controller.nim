## This module implements the editor controller node.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import karax/[karax, karaxdsl, kbase, vdom]
import ./[permute]
import ../../../../../apppkg/[editorpermuter, simulator]
import ../../../../../nazopuyopkg/[nazopuyo]

proc initEditorControllerNode*(editorPermuter: var EditorPermuter, id = ""):
    VNode {.inline.} =
  ## Returns the editor controller node.
  let
    workerRunning = editorPermuter.solving or editorPermuter.permuting

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
      let (fixMoves, allowDouble, allowLastDouble) = getPermuteData(
        id, nazoPuyo.moveCount)
      editorPermuter.permute fixMoves, allowDouble, allowLastDouble

  result = buildHtml(tdiv(class = "buttons")):
    button(class = solveButtonClass, disabled = workerRunning,
           onclick = () => editorPermuter.solve):
      text "解探索"
    button(class = permuteButtonClass, disabled = workerRunning,
           onclick = permuteHandler):
      text "ツモ並べ替え"
    button(class = focusButtonClass,
           onclick = () => editorPermuter.toggleFocus):
      text "シミュを操作"
