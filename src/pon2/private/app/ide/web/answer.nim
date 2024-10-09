## This module implements the answer simulator node.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import karax/[vdom]
import ../../../../app/[ide, simulator]

proc newAnswerSimulatorNode*(ide: Ide, id: string): VNode {.inline.} =
  ## Returns the answer simulator node.
  ide.answerSimulator.newSimulatorNode(wrapSection = false, id = id)
