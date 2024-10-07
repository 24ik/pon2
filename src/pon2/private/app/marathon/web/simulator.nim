## This module implements the marathon simulator node.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import karax/[vdom]
import ../../../../app/[marathon, simulator]

proc newMarathonSimulatorNode*(marathon: Marathon, id: string): VNode {.inline.} =
  ## Returns the marathon simulator node.
  ## `id` is shared with other node-creating procedures and need to be unique.
  marathon.simulator.newSimulatorNode(wrapSection = false, id = id)
