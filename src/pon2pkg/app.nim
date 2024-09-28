## This module implements the application for [Puyo Puyo](https://puyo.sega.jp/)
## and [Nazo Puyo](https://vc.sega.jp/3ds/nazopuyo/).
##
## Submodule Documentations:
## - [color](./app/color.html)
## - [generate](./app/generate.html)
## - [gui](./app/gui.html)
## - [key](./app/key.html)
## - [marathon](./app/marathon.html)
## - [nazopuyo](./app/nazopuyo.html)
## - [permute](./app/permute.html)
## - [simulator](./app/simulator.html)
## - [solve](./app/solve.html)
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
  gui.GuiApplicationReplay, gui.GuiApplication, gui.initGuiApplication, gui.simulator,
  gui.simulatorRef, gui.replaySimulator, gui.replaySimulatorRef, gui.replay,
  gui.focusReplay, gui.solving, gui.permuting, gui.progressBar, gui.toggleFocus,
  gui.solve, gui.permute, gui.nextReplay, gui.prevReplay, gui.operate
export key.KeyEvent, key.initKeyEvent
export
  marathon.MarathonMatchResult, marathon.Marathon, marathon.initMarathon,
  marathon.simulator, marathon.simulatorRef, marathon.matchResult,
  marathon.focusSimulator, marathon.toggleFocus, marathon.nextResultPage,
  marathon.prevResultPage, marathon.match, marathon.play, marathon.operate
export
  nazopuyo.NazoPuyoWrap, nazopuyo.initNazoPuyoWrap, nazopuyo.get, nazopuyo.rule,
  nazopuyo.`rule=`, nazopuyo.`==`
export permute.permute
export
  simulator.SimulatorKind, simulator.SimulatorMode, simulator.SimulatorState,
  simulator.SimulatorEditing, simulator.Simulator, simulator.initSimulator,
  simulator.copy, simulator.rule, simulator.kind, simulator.mode, simulator.`rule=`,
  simulator.`kind=`, simulator.`mode=`, simulator.nazoPuyoWrap,
  simulator.nazoPuyoWrapBeforeMoves, simulator.`pairsPositions=`, simulator.editing,
  simulator.`editingCell=`, simulator.state, simulator.score,
  simulator.operatingPosition, simulator.toggleInserting, simulator.toggleFocus,
  simulator.moveCursorUp, simulator.moveCursorDown, simulator.moveCursorRight,
  simulator.moveCursorLeft, simulator.deletePairPosition, simulator.writeCell,
  simulator.shiftFieldUp, simulator.shiftFieldDown, simulator.shiftFieldRight,
  simulator.shiftFieldLeft, simulator.flipFieldV, simulator.flipFieldH, simulator.flip,
  simulator.`requirementKind=`, simulator.`requirementColor=`,
  simulator.`requirementNumber=`, simulator.undo, simulator.redo,
  simulator.moveOperatingPositionRight, simulator.moveOperatingPositionLeft,
  simulator.rotateOperatingPositionRight, simulator.rotateOperatingPositionLeft,
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
  export simulator.initSimulatorNode
else:
  export color.toNiguiColor
  export
    gui.GuiApplicationControl, gui.GuiApplicationWindow, gui.runKeyboardEventHandler,
    gui.initKeyboardEventHandler, gui.initGuiApplicationControl,
    gui.initGuiApplicationWindow
  export key.toKeyEvent
  export simulator.SimulatorControl, simulator.initSimulatorControl
