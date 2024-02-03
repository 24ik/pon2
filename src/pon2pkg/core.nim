## This module implements the core of [Puyo Puyo](https://puyo.sega.jp/).
## With `import pon2pkg/core`, you can use all features provided by this module.
## Also, you can write such as `import pon2pkg/corepkg/cell` to import
## submodules individually.
##
## Submodule Documentations:
## - [cell](./corepkg/cell.html)
## - [environment](./corepkg/environment.html)
## - [field](./corepkg/field.html)
## - [fieldtype](./corepkg/fieldtype.html)
## - [misc](./corepkg/misc.html)
## - [moveresult](./corepkg/moveresult.html)
## - [pair](./corepkg/pair.html)
## - [position](./corepkg/position.html)
## - [rule](./corepkg/rule.html)
##
## Compile Options:
## | Option                          | Description                 | Default |
## | ------------------------------- | --------------------------- | ------- |
## | `-d:pon2.waterheight=<int>`     | Height of the water.        | `8`     |
## | `-d:Pon2TsuGarbageRate=<int>`   | Garbage rate in Tsu rule.   | `70`    |
## | `-d:Pon2WaterGarbageRate=<int>` | Garbage rate in Water rule. | `90`    |
## | `-d:Pon2Avx2=<bool>`            | Use AVX2 instructions.      | `true`  |
## | `-d:Pon2Bmi2=<bool>`            | Use BMI2 instructions.      | `true`  |
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ./corepkg/[cell, environment, field, fieldtype, misc, moveresult, pair,
                  position, rule]

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
export fieldtype.Height, fieldtype.Width, fieldtype.WaterHeight,
  fieldtype.AirHeight, fieldtype.Row, fieldtype.Column, fieldtype.WaterRow,
  fieldtype.AirRow
export misc.SimulatorHost, misc.SimulatorKind, misc.SimulatorMode,
  misc.NoticeGarbage, misc.GarbageRates
export moveresult.MoveResult, moveresult.initMoveResult, moveresult.chainCount,
  moveresult.puyoCount, moveresult.colorCount, moveresult.garbageCount,
  moveresult.puyoCounts, moveresult.colorCounts, moveresult.garbageCounts,
  moveresult.colors, moveresult.colorsSeq, moveresult.colorPlaces,
  moveresult.colorConnects, moveresult.score, moveresult.noticeGarbageCounts
export pair.Deque, pair.`[]`, pair.`[]=`, pair.addFirst, pair.addLast,
  pair.clear, pair.contains, pair.initDeque, pair.len, pair.peekFirst,
  pair.peekLast, pair.popFirst, pair.popLast, pair.shrink, pair.toDeque,
  pair.items, pair.mitems, pair.pairs, pair.Pair, pair.Pairs, pair.initPair,
  pair.initPairs, pair.axis, pair.child, pair.isDouble, pair.`axis=`,
  pair.`child=`, pair.`==`, pair.swapped, pair.swap, pair.puyoCount,
  pair.colorCount, pair.garbageCount, pair.parsePair, pair.`$`, pair.parsePairs,
  pair.toUriQuery, pair.toArray
export position.Direction, position.Position, position.Positions,
  position.AllPositions, position.DoublePositions, position.initPosition,
  position.axisColumn, position.childColumn, position.childDirection,
  position.movedRight, position.movedLeft, position.moveRight,
  position.moveLeft, position.rotatedRight, position.rotatedLeft,
  position.rotateRight, position.rotateLeft, position.`$`,
  position.parsePosition, position.parsePositions, position.toUriQuery
export rule.Rule, rule.parseRule
