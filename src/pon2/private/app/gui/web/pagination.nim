## This module implements the editor pagination node.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, sugar]
import karax/[karax, karaxdsl, vdom]
import ../../../../app/[gui]

proc initEditorPaginationNode*(guiApplication: ref GuiApplication): VNode {.inline.} =
  ## Returns the editor pagination node.
  let showIdx =
    if guiApplication[].answer.pairsPositionsSeq.len == 0:
      0
    else:
      guiApplication[].answer.index.succ

  result = buildHtml(
    nav(class = "pagination", role = "navigation", aria - label = "pagination")
  ):
    button(
      class = "button pagination-link", onclick = () => guiApplication[].prevAnswer
    ):
      span(class = "icon"):
        italic(class = "fa-solid fa-backward-step")
    button(class = "button pagination-link is-static"):
      text &"{showIdx} / {guiApplication[].answer.pairsPositionsSeq.len}"
    button(
      class = "button pagination-link", onclick = () => guiApplication[].nextAnswer
    ):
      span(class = "icon"):
        italic(class = "fa-solid fa-forward-step")
