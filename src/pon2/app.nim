## This module implements the application for [Puyo Puyo](https://puyo.sega.jp/)
## and [Nazo Puyo](https://vc.sega.jp/3ds/nazopuyo/).
##
## Submodule Documentations:
## - [color](./app/color.html)
## - [generate](./app/generate.html)
## - [ide](./app/ide.html)
## - [key](./app/key.html)
## - [marathon](./app/marathon.html)
## - [nazopuyo](./app/nazopuyo.html)
## - [permute](./app/permute.html)
## - [simulator](./app/simulator.html)
## - [solve](./app/solve.html)
##
## Compile Options:
## | Option                         | Description                      | Default             |
## | ------------------------------ | -------------------------------- | ------------------- |
## | `-d:pon2.path=<str>`           | URI path of the web IDE.         | `/pon2/`            |
## | `-d:pon2.workerfilename=<str>` | File name of the web worker.     | `worker.min.js`     |
## | `-d:pon2.assets.native=<str>`  | Assets directory for native app. | `<Pon2Root>/assets` |
## | `-d:pon2.assets.web=<str>`     | Assets directory for web app.    | `./assets`          |
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ./app/[color, generate, ide, key, marathon, nazopuyo, permute, simulator, solve]

export
  color.Color, color.SelectColor, color.GhostColor, color.WaterColor, color.DefaultColor
export
  generate.GenerateError, generate.GenerateRequirementColor,
  generate.GenerateRequirement, generate.GenerateOption, generate.generate
export
  ide.AnswerData, ide.Ide, ide.newIde, ide.simulator, ide.answerSimulator,
  ide.answerData, ide.focusAnswer, ide.solving, ide.permuting, ide.progressBarData,
  ide.toggleFocus, ide.solve, ide.permute, ide.nextAnswer, ide.prevAnswer, ide.toUri,
  ide.parseIde, ide.operate
export key.KeyEvent, key.initKeyEvent
export
  marathon.MarathonMatchResult, marathon.Marathon, marathon.newMarathon,
  marathon.simulator, marathon.matchResult, marathon.focusSimulator, marathon.isReady,
  marathon.toggleFocus, marathon.nextResultPage, marathon.prevResultPage,
  marathon.match, marathon.play, marathon.operate
export
  nazopuyo.NazoPuyoWrap, nazopuyo.initNazoPuyoWrap, nazopuyo.get, nazopuyo.rule,
  nazopuyo.`rule=`, nazopuyo.`==`
export permute.permute
export
  simulator.SimulatorKind, simulator.SimulatorMode, simulator.SimulatorState,
  simulator.SimulatorEditing, simulator.Simulator, simulator.newSimulator,
  simulator.copy, simulator.nazoPuyoWrap, simulator.nazoPuyoWrapBeforeMoves,
  simulator.rule, simulator.kind, simulator.mode, simulator.`rule=`, simulator.`kind=`,
  simulator.`mode=`, simulator.editing, simulator.`editingCell=`,
  simulator.`pairsPositions=`, simulator.`positions=`, simulator.state, simulator.score,
  simulator.positions, simulator.operatingIndex, simulator.operatingPosition,
  simulator.toggleInserting, simulator.toggleFocus, simulator.moveCursorUp,
  simulator.moveCursorDown, simulator.moveCursorRight, simulator.moveCursorLeft,
  simulator.deletePairPosition, simulator.writeCell, simulator.shiftFieldUp,
  simulator.shiftFieldDown, simulator.shiftFieldRight, simulator.shiftFieldLeft,
  simulator.flipFieldV, simulator.flipFieldH, simulator.flip,
  simulator.`requirementKind=`, simulator.`requirementColor=`,
  simulator.`requirementNumber=`, simulator.undo, simulator.redo,
  simulator.moveOperatingPositionRight, simulator.moveOperatingPositionLeft,
  simulator.rotateOperatingPositionRight, simulator.rotateOperatingPositionLeft,
  simulator.forward, simulator.backward, simulator.reset, simulator.toUriQuery,
  simulator.parseSimulator, simulator.operate
export solve.SolveAnswer, solve.solve

when defined(js):
  import ./app/ide/[web as ideWeb]
  import ./app/marathon/[web as marathonWeb]
  import ./app/simulator/[web as simulatorWeb]

  export color.toColorCode
  export
    ideWeb.runKeyboardEventHandler, ideWeb.newKeyboardEventHandler, ideWeb.newIdeNode
  export key.toKeyEvent
  export
    marathon.asyncLoadData, marathonWeb.runKeyboardEventHandler,
    marathonWeb.newKeyboardEventHandler, marathonWeb.newMarathonNode
  export simulatorWeb.newSimulatorNode
else:
  import ./app/ide/[native as ideNative]
  import ./app/simulator/[native as simulatorNative]

  export color.toNiguiColor
  export
    ideNative.IdeControl, ideNative.IdeWindow, ideNative.runKeyboardEventHandler,
    ideNative.newKeyboardEventHandler, ideNative.newIdeControl, ideNative.newIdeWindow
  export marathon.loadData
  export key.toKeyEvent
  export simulatorNative.SimulatorControl, simulatorNative.newSimulatorControl
