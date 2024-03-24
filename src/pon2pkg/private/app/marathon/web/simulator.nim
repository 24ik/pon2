## This module implements the marathon simulator node.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import karax/[vdom]
import ../../../../app/[marathon, simulator]

proc initMarathonSimulatorNode*(marathon: var Marathon, id = ""): VNode {.inline.} =
  ## Returns the marathon simulator node.
  ## `id` is shared with other node-creating procedures and need to be unique.
  marathon.simulator.initSimulatorNode(wrapSection = false, id = id)
