## This module implements the answer pagination node.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[options, strformat, sugar]
import karax/[karax, karaxdsl, vdom]
import ../../../../apppkg/[editorpermuter]

proc initAnswerPaginationNode*(editorPermuter: var EditorPermuter): VNode
                              {.inline.} =
  ## Returns the answer pagination node.
  let showIdx =
    if editorPermuter.answers.get.len == 0: 0
    else: editorPermuter.answerIdx.succ

  result = buildHtml(nav(class = "pagination", role = "navigation",
                         aria-label = "pagination")):
    button(class = "button pagination-link",
           onclick = () => editorPermuter.prevAnswer):
      span(class = "icon"):
        italic(class = "fa-solid fa-backward-step")
    button(class = "button pagination-link is-static"):
      text &"{showIdx} / {editorPermuter.answers.get.len}"
    button(class = "button pagination-link",
           onclick = () => editorPermuter.nextAnswer):
      span(class = "icon"):
        italic(class = "fa-solid fa-forward-step")
