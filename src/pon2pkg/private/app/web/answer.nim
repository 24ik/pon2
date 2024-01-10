## This module implements the answer node.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[options, strformat, sugar]
import karax/[karax, karaxdsl, vdom]
import ../../../apppkg/[editorpermuter]
import ../../../simulatorpkg/[web]

proc answerNode*(editorPermuter: var EditorPermuter): VNode {.inline.} =
  ## Returns the answer node.
  let answerSimulatorNode =
    editorPermuter.answerSimulator[].initSimulatorDom(
      setKeyHandler = false, wrapSection = false)

  result = buildHtml(tdiv):
    tdiv(class = "block"):
      nav(class = "pagination", role = "navigation", aria-label = "pagination"):
        button(class = "button pagination-link", onclick = () =>
            editorPermuter.prevAnswer):
          span(class = "icon"):
            italic(class = "fa-solid fa-backward-step")
        button(class = "button pagination-link is-static"):
          if editorPermuter.answers.get.len == 0:
            text "0 / 0"
          else:
            text &"{editorPermuter.answerIdx.succ} / {editorPermuter.answers.get.len}"
        button(class = "button pagination-link", onclick = () =>
            editorPermuter.nextAnswer):
          span(class = "icon"):
            italic(class = "fa-solid fa-forward-step")
    if editorPermuter.answers.get.len > 0:
      tdiv(class = "block"):
        answerSimulatorNode
