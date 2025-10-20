## This module implements the editor pagination node.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, sugar]
import karax/[karax, karaxdsl, vdom]
import ../../../../app/[ide]

proc newEditorPaginationNode*(ide: Ide): VNode {.inline.} =
  ## Returns the editor pagination node.
  let showIdx =
    if ide.answerData.pairsPositionsSeq.len == 0: 0 else: ide.answerData.index.succ

  result = buildHtml(nav(class = "pagination")):
    button(class = "button pagination-link", onclick = () => ide.prevAnswer):
      span(class = "icon"):
        italic(class = "fa-solid fa-backward-step")
    button(class = "button pagination-link is-static"):
      text &"{showIdx} / {ide.answerData.pairsPositionsSeq.len}"
    button(class = "button pagination-link", onclick = () => ide.nextAnswer):
      span(class = "icon"):
        italic(class = "fa-solid fa-forward-step")
