## This module implements the messages node.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import karax/[karaxdsl, vdom]
import ../[render]
import ../../../apppkg/[simulator]

proc initMessagesNode*(simulator: var Simulator): VNode {.inline.} =
  ## Returns the messages node.
  buildHtml(text simulator.getMessages.state)
