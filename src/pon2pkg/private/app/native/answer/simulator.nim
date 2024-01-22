## This module implements the answer simulator control.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ../../../../apppkg/[editorpermuter, simulator]

proc initAnswerSimulatorControl*(editorPermuter: ref EditorPermuter):
    SimulatorControl {.inline.} =
  ## Returns the answer simulator control.
  editorPermuter[].answerSimulator.initSimulatorControl
