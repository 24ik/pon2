## This module implements the simulator.
## With `import pon2pkg/simulator`, you can use all features provided by this
## module.
## Also, you can write such as `import pon2pkg/simulatorpkg/simulator` to import
## submodules individually.
##
## Submodule Documentations:
## - [Simulator Core](./simulatorpkg/simulator.html)
## - [Native Simulator](./simulatorpkg/native.html)
## - Web Simulator
##

{.experimental: "strictDefs".}

import ./simulatorpkg/[simulator]

export simulator.SimulatorState, simulator.Simulator, simulator.KeyEvent,
  simulator.initKeyEvent, simulator.initSimulator, simulator.`rule`,
  simulator.`kind`, simulator.`mode`, simulator.`rule=`, simulator.`kind=`,
  simulator.`mode=`, simulator.tsuNazoPuyo, simulator.waterNazoPuyo,
  simulator.originalTsuNazoPuyo, simulator.originalWaterNazoPuyo,
  simulator.pairs, simulator.originalPairs, simulator.withNazoPuyo,
  simulator.withEnvironment, simulator.withField, simulator.toggleInserting,
  simulator.toggleFocus, simulator.moveCursorUp, simulator.moveCursorDown,
  simulator.moveCursorRight, simulator.moveCursorLeft, simulator.deletePair,
  simulator.writeCell, simulator.shiftFieldUp, simulator.shiftFieldDown,
  simulator.shiftFieldRight, simulator.shiftFieldLeft, simulator.flipFieldV,
  simulator.flipFieldH, simulator.`requirementKind=`,
  simulator.`requirementColor=`, simulator.`requirementNumber=`, simulator.undo,
  simulator.redo, simulator.moveNextPositionRight,
  simulator.moveNextPositionLeft, simulator.rotateNextPositionRight,
  simulator.rotateNextPositionLeft, simulator.forward, simulator.backward,
  simulator.reset, simulator.toUri, simulator.operate

when defined(js):
  import ./simulatorpkg/[web]

  export web.toKeyEvent, web.runKeyboardEventHandler,
    web.initKeyboardEventHandler, web.initPuyoSimulatorDom,
    web.initPuyoSimulatorAnswerDom
else:
  import ./simulatorpkg/[native]

  export native.toKeyEvent, native.PuyoSimulatorControl, native.PuyoSimulatorWindow,
    native.runKeyboardEventHandler, native.initKeyboardEventHandler,
    native.initPuyoSimulatorControl, native.initPuyoSimulatorWindow,
    native.initPuyoSimulatorAnswerControl