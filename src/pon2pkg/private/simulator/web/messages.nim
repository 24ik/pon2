## This module implements the messages frame.
##

{.experimental: "strictDefs".}

import karax/[karaxdsl, vdom]
import ../[render]
import ../../../simulatorpkg/[simulator]

proc messagesFrame*(simulator: var Simulator): VNode {.inline.} =
  ## Returns the messages frame.
  buildHtml(text simulator.getMessage)
