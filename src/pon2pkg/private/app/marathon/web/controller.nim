## This module implements the marathon controller node.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import karax/[karax, karaxdsl, kbase, vdom]
import ../../../../apppkg/[marathon]

proc initMarathonControllerNode*(marathon: var Marathon): VNode {.inline.} =
  ## Returns the marathon controller node.
  let focusButtonClass =
    if marathon.focusSimulator: kstring"button"
    else: kstring"button is-selected is-primary"

  result = buildHtml(tdiv(class = "buttons")):
    button(class = focusButtonClass,
           onclick = () => marathon.toggleFocus):
      text "検索結果を操作"
