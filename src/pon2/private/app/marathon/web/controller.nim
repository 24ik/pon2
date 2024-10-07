## This module implements the marathon controller node.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import karax/[karax, karaxdsl, kbase, vdom]
import ../../../../app/[marathon]

proc newMarathonPlayControllerNode*(marathon: Marathon): VNode {.inline.} =
  ## Returns the marathon play controller node.
  buildHtml(tdiv):
    text "以下からランダムにツモ読込"
    tdiv(class = "buttons"):
      button(
        class = "button",
        onclick = () => marathon.play,
        disabled = marathon.matchResult.strings.len == 0,
      ):
        text "検索結果"
      button(class = "button", onclick = () => marathon.play(false)):
        text "全ツモ"

proc newMarathonFocusControllerNode*(marathon: Marathon): VNode {.inline.} =
  ## Returns the marathon focus controller node.
  let focusButtonClass =
    if marathon.focusSimulator:
      kstring"button is-selected is-primary"
    else:
      kstring"button"

  result = buildHtml(
    button(class = focusButtonClass, onclick = () => marathon.toggleFocus)
  ):
    text "シミュを操作"
