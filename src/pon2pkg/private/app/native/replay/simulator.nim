## This module implements the replay simulator control.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ../../../../apppkg/[editorpermuter, simulator]

proc initReplaySimulatorControl*(editorPermuter: ref EditorPermuter):
    SimulatorControl {.inline.} =
  ## Returns the replay simulator control.
  editorPermuter[].replaySimulator.initSimulatorControl
