## This module implements the replay simulator node.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import karax/[vdom]
import ../../../../apppkg/[editorpermuter, simulator]

proc initReplaySimulatorNode*(editorPermuter: var EditorPermuter, id = ""):
    VNode {.inline.} =
  ## Returns the replay simulator node.
  ## `id` is shared with other node-creating procedures and need to be unique.
  editorPermuter.replaySimulator[].initSimulatorNode(false, false, id)
