## This module implements the answer simulator control.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ../../../../app/[ide]
import ../../../../app/simulator/[native]

proc newAnswerSimulatorControl*(ide: Ide): SimulatorControl {.inline.} =
  ## Returns the answer simulator control.
  ide.answerSimulator.newSimulatorControl
