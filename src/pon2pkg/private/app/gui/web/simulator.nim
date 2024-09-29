## This module implements the editor simulator node.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import karax/[vdom]
import ../../../../app/[gui, simulator]

proc initEditorSimulatorNode*(
    guiApplication: ref GuiApplication, id = ""
): VNode {.inline.} =
  ## Returns the editor simulator node.
  ## `id` is shared with other node-creating procedures and need to be unique.
  guiApplication[].answerSimulatorRef.initSimulatorNode(wrapSection = false, id = id)
