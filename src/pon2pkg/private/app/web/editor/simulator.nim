## This module implements the editor simulator node.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import karax/[vdom]
import ../../../../apppkg/[editorpermuter, simulator]

proc initEditorSimulatorNode*(editorPermuter: var EditorPermuter, id = ""):
    VNode {.inline.} =
  ## Returns the editor simulator node.
  ## `id` is shared with other node-creating procedures and need to be unique.
  editorPermuter.replaySimulator[].initSimulatorNode(false, false, id)
