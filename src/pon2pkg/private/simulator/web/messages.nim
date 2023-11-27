## This module implements the messages node.
##

{.experimental: "strictDefs".}

import karax/[karaxdsl, vdom]
import ../[render]
import ../../../simulatorpkg/[simulator]

proc messagesNode*(simulator: var Simulator): VNode {.inline.} =
  ## Returns the messages node.
  buildHtml(text simulator.getMessage)
