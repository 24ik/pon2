## This module implements the answer simulator control.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ../../../../app/[ide, simulator]

proc newAnswerSimulatorControl*(ide: Ide): SimulatorControl {.inline.} =
  ## Returns the answer simulator control.
  ide.answerSimulator.newSimulatorControl
