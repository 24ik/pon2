## This module implements the editor pagination node.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[options, strformat, sugar]
import karax/[karax, karaxdsl, vdom]
import ../../../../apppkg/[editorpermuter]

proc initEditorPaginationNode*(editorPermuter: var EditorPermuter): VNode
                              {.inline.} =
  ## Returns the editor pagination node.
  let showIdx =
    if editorPermuter.replayData.get.len == 0: 0
    else: editorPermuter.replayIdx.succ

  result = buildHtml(nav(class = "pagination", role = "navigation",
                         aria-label = "pagination")):
    button(class = "button pagination-link",
           onclick = () => editorPermuter.prevReplay):
      span(class = "icon"):
        italic(class = "fa-solid fa-backward-step")
    button(class = "button pagination-link is-static"):
      text &"{showIdx} / {editorPermuter.replayData.get.len}"
    button(class = "button pagination-link",
           onclick = () => editorPermuter.nextReplay):
      span(class = "icon"):
        italic(class = "fa-solid fa-forward-step")
