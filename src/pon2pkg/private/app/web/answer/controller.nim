## This module implements the answer controller node.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import karax/[karax, karaxdsl, kbase, vdom]
import ../../../../apppkg/[editorpermuter]

proc initAnswerControllerNode*(editorPermuter: var EditorPermuter): VNode
                              {.inline.} =
  ## Returns the answer controller node.
  let
    focusButtonClass =
      if editorPermuter.focusAnswer: kstring"button is-selected is-primary"
      else: kstring"button"
    solveButtonClass =
      if editorPermuter.solving: kstring"button is-loading"
      else: kstring"button"

  result = buildHtml(tdiv(class = "buttons")):
    button(class = focusButtonClass,
           onclick = () => editorPermuter.toggleFocus):
      text "解答を操作"
    button(class = solveButtonClass, disabled = editorPermuter.solving,
           onclick = () => editorPermuter.solve):
      text "解探索"
