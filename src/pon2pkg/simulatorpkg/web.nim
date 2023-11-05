## This module provides some APIs for Web GUI application.
##

{.experimental: "strictDefs".}

import ../private/simulator/web/[main]

export main.toKeyEvent, main.runKeyboardEventHandler,
  main.initKeyboardEventHandler, main.initPuyoSimulatorDom,
  main.initPuyoSimulatorAnswerDom
