## This module implements [Puyo Puyo](https://puyo.sega.jp/) and
## [Nazo Puyo](https://vc.sega.jp/3ds/nazopuyo/).
##
## Submodule Documentations:
## - [cell](./core/cell.html)
## - [field](./core/field.html)
## - [fieldtype](./core/fieldtype.html)
## - [host](./core/host.html)
## - [mark](./core/mark.html)
## - [moveresult](./core/moveresult.html)
## - [nazopuyo](./core/nazopuyo.html)
## - [notice](./core/notice.html)
## - [pair](./core/pair.html)
## - [pairposition](./core/pairposition.html)
## - [position](./core/position.html)
## - [puyopuyo](./core/puyopuyo.html)
## - [requirement](./core/requirement.html)
## - [rule](./core/rule.html)
##
## Compile Options:
## | Option                            | Description                 | Default |
## | --------------------------------- | --------------------------- | ------- |
## | `-d:pon2.waterheight=<int>`       | Height of the water.        | `8`     |
## | `-d:pon2.garbagerate.tsu=<int>`   | Garbage rate in Tsu rule.   | `70`    |
## | `-d:pon2.garbagerate.water=<int>` | Garbage rate in Water rule. | `90`    |
## | `-d:pon2.avx2=<bool>`             | Use AVX2 instructions.      | `true`  |
## | `-d:pon2.bmi2=<bool>`             | Use BMI2 instructions.      | `true`  |
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import
  ./core/[
    cell, field, fieldtype, host, mark, moveresult, nazopuyo, notice, pair,
    pairposition, position, puyopuyo, requirement, rule,
  ]

export cell.Cell, cell.ColorPuyo, cell.Puyo, cell.parseCell
export
  field.TsuField, field.WaterField, field.initField, field.toTsuField,
  field.toWaterField, field.`[]`, field.`[]=`, field.insert, field.removeSqueeze,
  field.puyoCount, field.colorCount, field.garbageCount, field.connect2,
  field.connect2V, field.connect2H, field.connect3, field.connect3V, field.connect3H,
  field.connect3L, field.shiftedUp, field.shiftedDown, field.shiftedRight,
  field.shiftedLeft, field.flippedV, field.flippedH, field.disappear,
  field.willDisappear, field.put, field.drop, field.toArray, field.parseField,
  field.`==`, field.rule, field.isDead, field.noneCount, field.invalidPositions,
  field.validPositions, field.validDoublePositions, field.shiftUp, field.shiftDown,
  field.shiftRight, field.shiftLeft, field.flipV, field.flipH, field.willDrop,
  field.move, field.move0, field.move1, field.move2, field.`$`, field.toUriQuery
export
  fieldtype.Height, fieldtype.Width, fieldtype.WaterHeight, fieldtype.AirHeight,
  fieldtype.Row, fieldtype.Column, fieldtype.WaterRow, fieldtype.AirRow
export host.SimulatorHost
export mark.MarkResult, mark.mark
export
  moveresult.MoveTrackingLevel, moveresult.MoveResult, moveresult.initMoveResult,
  moveresult.`==`, moveresult.puyoCount, moveresult.colorCount, moveresult.garbageCount,
  moveresult.puyoCounts, moveresult.colorCounts, moveresult.garbageCounts,
  moveresult.colors, moveresult.colorsSeq, moveresult.colorPlaces,
  moveresult.colorConnects, moveresult.score, moveresult.noticeGarbageCounts
export
  nazopuyo.NazoPuyo, nazopuyo.initNazoPuyo, nazopuyo.`==`, nazopuyo.toTsuNazoPuyo,
  nazopuyo.toWaterNazoPuyo, nazopuyo.rule, nazopuyo.moveCount, nazopuyo.`$`,
  nazopuyo.parseNazoPuyo, nazopuyo.toUriQuery
export notice.NoticeGarbage, notice.GarbageRates, notice.noticeGarbageCounts
export
  pair.Pair, pair.initPair, pair.axis, pair.child, pair.isDouble, pair.`axis=`,
  pair.`child=`, pair.swapped, pair.swap, pair.puyoCount, pair.colorCount,
  pair.garbageCount, pair.parsePair, pair.toUriQuery
export
  pairposition.PairPosition, pairposition.PairsPositions, pairposition.puyoCount,
  pairposition.colorCount, pairposition.garbageCount, pairposition.`$`,
  pairposition.parsePairPosition, pairposition.parsePairsPositions,
  pairposition.toUriQuery
export
  position.Direction, position.Position, position.AllPositions,
  position.AllDoublePositions, position.initPosition, position.axisColumn,
  position.childColumn, position.childDirection, position.movedRight,
  position.movedLeft, position.moveRight, position.moveLeft, position.rotatedRight,
  position.rotatedLeft, position.rotateRight, position.rotateLeft,
  position.parsePosition, position.toUriQuery
export
  puyopuyo.PuyoPuyo, puyopuyo.reset, puyopuyo.initPuyoPuyo, puyopuyo.`==`,
  puyopuyo.toTsuPuyoPuyo, puyopuyo.toWaterPuyoPuyo, puyopuyo.rule,
  puyopuyo.operatingIndex, puyopuyo.incrementoperatingIndex,
  puyopuyo.decrementoperatingIndex, puyopuyo.movingCompleted,
  puyopuyo.operatingPairPosition, puyopuyo.puyoCount, puyopuyo.colorCount,
  puyopuyo.garbageCount, puyopuyo.move, puyopuyo.move0, puyopuyo.move1, puyopuyo.move2,
  puyopuyo.`$`, puyopuyo.parsePuyoPuyo, puyopuyo.toUriQuery
export
  requirement.RequirementKind, requirement.RequirementColor,
  requirement.RequirementNumber, requirement.Requirement, requirement.NoColorKinds,
  requirement.NoNumberKinds, requirement.ColorKinds, requirement.NumberKinds,
  requirement.`==`, requirement.isSupported, requirement.`$`,
  requirement.parseRequirement, requirement.toUriQuery
export rule.Rule, rule.parseRule
