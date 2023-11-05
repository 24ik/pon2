## This module provides some APIs for native GUI application.
##
## `-d:ssl` compile option is required.
##

{.experimental: "strictDefs".}

import ../private/simulator/native/[main]

export main.toKeyEvent, main.PuyoSimulatorControl, main.PuyoSimulatorWindow,
  main.runKeyboardEventHandler, main.initKeyboardEventHandler,
  main.initPuyoSimulatorControl, main.initPuyoSimulatorWindow,
  main.initPuyoSimulatorAnswerControl
