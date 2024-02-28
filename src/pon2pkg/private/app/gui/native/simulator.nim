## This module implements the editor simulator control.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ../../../../app/[gui, simulator]

proc initEditorSimulatorControl*(
    guiApplication: ref GuiApplication
): SimulatorControl {.inline.} =
  ## Returns the editor simulator control.
  guiApplication[].replaySimulator.initSimulatorControl
