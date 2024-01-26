## This module implements the marathon controller node.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import karax/[karax, karaxdsl, kbase, vdom]
import ../../../../apppkg/[marathon]

proc initMarathonPlayControllerNode*(marathon: var Marathon): VNode {.inline.} =
  ## Returns the marathon play controller node.
  buildHtml(tdiv):
    text "以下からランダムにツモ読込"
    tdiv(class = "buttons"):
      button(class = "button", onclick = () => marathon.play,
            disabled = marathon.matchPairsStrsSeq.len == 0):
        text "検索結果"
      button(class = "button", onclick = () => marathon.play(false)):
        text "全ツモ"

proc initMarathonFocusControllerNode*(marathon: var Marathon): VNode
                                     {.inline.} =
  ## Returns the marathon focus controller node.
  let focusButtonClass =
    if marathon.focusSimulator: kstring"button"
    else: kstring"button is-selected is-primary"

  result = buildHtml(button(class = focusButtonClass,
                            onclick = () => marathon.toggleFocus)):
    text "検索結果を操作"
