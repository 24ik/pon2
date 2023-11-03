## This module implements the messages frame.
##

{.experimental: "strictDefs".}

import karax/[karaxdsl, vdom]
import ../[simulator]
import ../../private/simulator/[render]

proc messagesFrame*(simulator: var Simulator): VNode {.inline.} =
  ## Returns the messages frame.
  buildHtml(text simulator.getMessage)
