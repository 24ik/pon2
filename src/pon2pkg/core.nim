## This module implements the core of [Puyo Puyo](https://puyo.sega.jp/).
## With `import pon2pkg/core`, you can use all features provided by this module.
## Also, you can write such as `import pon2pkg/corepkg/cell` to import
## submodules individually.
##
## Submodule Documentations:
## - [Cell](./corepkg/cell.html)
## - [Environment](./corepkg/environment.html)
## - [Field](./corepkg/field.html)
## - [Misc](./corepkg/misc.html)
## - [MoveResult](./corepkg/moveresult.html)
## - [Pair](./corepkg/pair.html)
## - [Position](./corepkg/position.html)
##
## Compile Options:
## | Option                | Description            | Default |
## | --------------------- | ---------------------- | ------- |
## | `-d:WaterHeight=<int> | Height of the water.   | `8`     |
## | `-d:avx2=<bool>`      | Use AVX2 instructions. | `true`  |
## | `-d:bmi2=<bool>`      | Use BMI2 instructions. | `true`  |
##

{.experimental: "strictDefs".}

import ./corepkg/[cell, environment, field, misc, moveresult, pair, position]

export cell.Cell, cell.ColorPuyo, cell.Puyo, cell.parseCell
export environment.Environment, environment.Environments,
  environment.toTsuEnvironment, environment.toWaterEnvironment,
  environment.flattenAnd, environment.addPair, environment.reset,
  environment.initEnvironment, environment.initTsuEnvironment,
  environment.initWaterEnvironment, environment.puyoCount,
  environment.colorCount, environment.garbageCount, environment.move,
  environment.moveWithRoughTracking, environment.moveWithDetailTracking,
  environment.moveWithFullTracking, environment.`$`, environment.toString,
  environment.parseEnvironment, environment.parseTsuEnvironment,
  environment.parseWaterEnvironment, environment.toUri,
  environment.parseEnvironments, environment.toArrays
export field.TsuField, field.WaterField, field.zeroField, field.zeroTsuField,
  field.zeroWaterField, field.toTsuField, field.toWaterField, field.`[]`,
  field.`[]=`, field.insert, field.removeSqueeze, field.puyoCount,
  field.colorCount, field.garbageCount, field.connect3, field.connect3V,
  field.connect3H, field.connect3L, field.shiftedUp, field.shiftedDown,
  field.shiftedRight, field.shiftedLeft, field.flippedV, field.flippedH,
  field.disappear, field.willDisappear, field.put, field.drop, field.toArray,
  field.parseField, field.Fields, field.rule, field.isDead, field.flattenAnd,
  field.noneCount, field.invalidPositions, field.validPositions,
  field.validDoublePositions, field.shiftUp, field.shiftDown, field.shiftRight,
  field.shiftLeft, field.flipV, field.flipH, field.move,
  field.moveWithRoughTracking, field.moveWithDetailTracking,
  field.moveWithFullTracking, field.parseTsuField, field.parseWaterField,
  field.`$`, field.toUriQuery, field.parseFields
when UseAvx2:
  export field.`==`
export misc.Height, misc.Width, misc.WaterHeight, misc.AirHeight, misc.Row,
  misc.Column, misc.WaterRow, misc.AirRow, misc.Rule, misc.SimulatorHost,
  misc.IzumiyaSimulatorKind, misc.IzumiyaSimulatorMode,
  misc.IshikawaSimulatorMode
export moveresult.NotSupportDefect, moveresult.MoveResult,
  moveresult.RoughMoveResult, moveresult.DetailMoveResult,
  moveresult.FullMoveResult, moveresult.initMoveResult,
  moveresult.initRoughMoveResult, moveresult.initDetailMoveResult,
  moveresult.initFullMoveResult, moveresult.chainCount, moveresult.puyoCount,
  moveresult.colorCount, moveresult.garbageCount, moveresult.puyoCounts,
  moveresult.colorCounts, moveresult.garbageCounts, moveresult.colors,
  moveresult.colorsSeq, moveresult.colorPlaces, moveresult.colorConnects,
  moveresult.score
export pair.Deque, pair.`[]`, pair.`[]=`, pair.addFirst, pair.addLast,
  pair.clear, pair.contains, pair.len, pair.peekFirst, pair.peekLast,
  pair.popFirst, pair.popLast, pair.shrink, pair.items, pair.mitems, pair.pairs,
  pair.Pair, pair.Pairs, pair.initPair, pair.initPairs, pair.axis, pair.child,
  pair.isDouble, pair.`axis=`, pair.`child=`, pair.`==`, pair.swapped,
  pair.swap, pair.puyoCount, pair.colorCount, pair.garbageCount, pair.parsePair,
  pair.`$`, pair.parsePairs, pair.toUriQuery, pair.toArray
export position.Direction, position.Position, position.Positions,
  position.DoublePositions, position.initPosition, position.axisColumn,
  position.childColumn, position.childDirection, position.movedRight,
  position.movedLeft, position.moveRight, position.moveLeft,
  position.rotatedRight, position.rotatedLeft, position.rotateRight,
  position.rotateLeft, position.`$`, position.parsePosition,
  position.parsePositions, position.toUriQuery
