## This module implements the editor simulator control.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ../../../../apppkg/[editorpermuter, simulator]

proc initEditorSimulatorControl*(editorPermuter: ref EditorPermuter):
    SimulatorControl {.inline.} =
  ## Returns the editor simulator control.
  editorPermuter[].replaySimulator.initSimulatorControl
