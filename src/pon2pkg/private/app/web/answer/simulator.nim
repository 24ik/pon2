## This module implements the answer simulator node.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import karax/[vdom]
import ../../../../apppkg/[editorpermuter, simulator]

proc initAnswerSimulatorNode*(editorPermuter: var EditorPermuter, id = ""):
    VNode {.inline.} =
  ## Returns the answer simulator node.
  ## `id` is shared with other node-creating procedures and need to be unique.
  editorPermuter.answerSimulator[].initSimulatorNode(false, false, id)
