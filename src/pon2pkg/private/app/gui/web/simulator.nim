## This module implements the editor simulator node.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import karax/[vdom]
import ../../../../app/[gui, simulator]

proc initEditorSimulatorNode*(
    guiApplication: var GuiApplication, id = ""
): VNode {.inline.} =
  ## Returns the editor simulator node.
  ## `id` is shared with other node-creating procedures and need to be unique.
  guiApplication.replaySimulator[].initSimulatorNode(
    setKeyHandler = false, wrapSection = false, id = id
  )
