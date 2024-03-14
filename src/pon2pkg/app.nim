## This module implements the application for [Puyo Puyo](https://puyo.sega.jp/)
## and [Nazo Puyo](https://vc.sega.jp/3ds/nazopuyo/).
##
## Submodule Documentations:
## - [color](./apppkg/color.html)
## - [generate](./apppkg/generate.html)
## - [gui](./apppkg/gui.html)
## - [key](./apppkg/key.html)
## - [marathon](./apppkg/marathon.html)
## - [nazopuyo](./apppkg/nazopuyo.html)
## - [permute](./apppkg/permute.html)
## - [simulator](./apppkg/simulator.html)
## - [solve](./apppkg/solve.html)
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ./app/[color, generate, gui, key, marathon, nazopuyo, permute, simulator, solve]

export
  color.Color, color.SelectColor, color.GhostColor, color.WaterColor, color.DefaultColor
export
  generate.GenerateError, generate.GenerateRequirementColor,
  generate.GenerateRequirement, generate.generate
export
  gui.GuiApplication, gui.initGuiApplication, gui.toggleFocus, gui.solve, gui.permute,
  gui.nextReplay, gui.prevReplay, gui.operate
export key.KeyEvent, key.initKeyEvent
export
  marathon.Marathon, marathon.initMarathon, marathon.toggleFocus,
  marathon.nextResultPage, marathon.prevResultPage, marathon.match, marathon.play,
  marathon.operate
export
  nazopuyo.NazoPuyoWrap, nazopuyo.initNazoPuyoWrap, nazopuyo.get, nazopuyo.rule,
  nazopuyo.`rule=`, nazopuyo.`==`
export permute.permute
export
  simulator.SimulatorKind, simulator.SimulatorMode, simulator.SimulatorState,
  simulator.Simulator, simulator.initSimulator, simulator.rule, simulator.kind,
  simulator.mode, simulator.`rule=`, simulator.`kind=`, simulator.`mode=`,
  simulator.score, simulator.originalNazoPuyoWrap, simulator.toggleInserting,
  simulator.toggleFocus, simulator.moveCursorUp, simulator.moveCursorDown,
  simulator.moveCursorRight, simulator.moveCursorLeft, simulator.deletePairPosition,
  simulator.writeCell, simulator.shiftFieldUp, simulator.shiftFieldDown,
  simulator.shiftFieldRight, simulator.shiftFieldLeft, simulator.flipFieldV,
  simulator.flipFieldH, simulator.`requirementKind=`, simulator.`requirementColor=`,
  simulator.`requirementNumber=`, simulator.undo, simulator.redo,
  simulator.moveNextPositionRight, simulator.moveNextPositionLeft,
  simulator.rotateNextPositionRight, simulator.rotateNextPositionLeft,
  simulator.forward, simulator.backward, simulator.reset, simulator.toUri,
  simulator.parseSimulator, simulator.operate
export solve.solve

when defined(js):
  export color.toColorCode
  export
    gui.runKeyboardEventHandler, gui.initKeyboardEventHandler,
    gui.initGuiApplicationNode
  export key.toKeyEvent
  export
    marathon.runKeyboardEventHandler, marathon.initKeyboardEventHandler,
    marathon.initMarathonNode
  export
    simulator.runKeyboardEventHandler, simulator.initKeyboardEventHandler,
    simulator.initSimulatorNode
else:
  export color.toNiguiColor
  export
    gui.GuiApplicationControl, gui.GuiApplicationWindow, gui.runKeyboardEventHandler,
    gui.initKeyboardEventHandler, gui.initGuiApplicationControl,
    gui.initGuiApplicationWindow
  export key.toKeyEvent
  export
    simulator.SimulatorControl, simulator.SimulatorWindow,
    simulator.runKeyboardEventHandler, simulator.initKeyboardEventHandler,
    simulator.initSimulatorControl, simulator.initSimulatorWindow
