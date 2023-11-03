## This module implements marking.
##

{.experimental: "strictDefs".}

import std/[options, sequtils, tables]
import ./[nazoPuyo]
import ../[cell, environment, field, moveResult, position]

type MarkResult* = enum
  ## Marking result.
  Accept
  WrongAnswer
  Dead
  ImpossibleMove
  SkipMove

const RequirementColorToCell = {
  RequirementColor.Garbage: Cell.Garbage, RequirementColor.Red: Cell.Red,
  RequirementColor.Green: Cell.Green, RequirementColor.Blue: Cell.Blue,
  RequirementColor.Yellow: Cell.Yellow,
  RequirementColor.Purple: Cell.Purple}.toTable

# ------------------------------------------------
# Mark
# ------------------------------------------------

func sum[T: SomeNumber or Natural](s: seq[T]): T {.inline.} =
  ## Returns the summation.
  ## This function removes the warning from `math.sum`.
  result = 0.T
  for e in s:
    result.inc e

func accept[
    F: TsuField or WaterField,
    R: MoveResult or RoughMoveResult or DetailMoveResult or FullMoveResult](
      req: Requirement, moveResult: R, field: F,
      disappearColors: Option[set[ColorPuyo]],
      disappearCount: Option[Natural]): bool {.inline.} =
  ## Returns `true` if the requirement is satisfied.
  # unsolvable (not supported) requirement
  if req.kind in {DisappearPlace, DisappearPlaceMore, DisappearConnect,
                  DisappearConnectMore}:
    if req.color.get == RequirementColor.Garbage:
      return false

  # check clear
  if req.kind in {Clear, ChainClear, ChainMoreClear}:
    let fieldCount = case req.color.get
    of RequirementColor.All: field.puyoCount
    of RequirementColor.Garbage: field.garbageCount
    of RequirementColor.Color: field.colorCount
    else: field.cellCount RequirementColorToCell[req.color.get]

    if fieldCount > 0:
      return false

  # check number
  if req.number.isNone:
    return true

  var hasMultipleCandidates = false
  let nowNum = case req.kind
  of DisappearColor, DisappearColorMore: disappearColors.get.card
  of DisappearCount, DisappearCountMore: disappearCount.get
  of Chain, ChainMore, ChainClear, ChainMoreClear: moveResult.chainCount
  else:
    hasMultipleCandidates = true
    0

  var nowNums = newSeq[int] 0
  case req.kind
  of DisappearColorSametime, DisappearColorMoreSametime:
    when R is DetailMoveResult:
      for counts in moveResult.disappearCounts:
        nowNums.add counts[ColorPuyo.low..ColorPuyo.high].countIt it > 0
  of DisappearCountSametime, DisappearCountMoreSametime:
    when R is DetailMoveResult:
      case req.color.get
      of RequirementColor.All:
        nowNums = moveResult.puyoCounts
      of RequirementColor.Color:
        nowNums = moveResult.colorCounts
      else:
        nowNums = moveResult.disappearCounts.mapIt it[
          RequirementColorToCell[req.color.get]].int
  of DisappearPlace, DisappearPlaceMore:
    when R is FullMoveResult:
      case req.color.get
      of RequirementColor.All, RequirementColor.Color:
        for countsArr in moveResult.detailDisappearCounts:
          nowNums.add sum countsArr[ColorPuyo.low..ColorPuyo.high].mapIt it.len
      of RequirementColor.Garbage:
        assert false
      else:
        nowNums = moveResult.detailDisappearCounts.mapIt it[
          RequirementColorToCell[req.color.get]].len
  of DisappearConnect, DisappearConnectMore:
    when R is FullMoveResult:
      case req.color.get
      of RequirementColor.All, RequirementColor.Color:
        for countsArray in moveResult.detailDisappearCounts:
          for counts in countsArray[ColorPuyo.low..ColorPuyo.high]:
            nowNums &= counts.mapIt it.int
      of RequirementColor.Garbage:
        assert false
      else:
        for countsArray in moveResult.detailDisappearCounts:
          nowNums &=
            countsArray[RequirementColorToCell[req.color.get]].mapIt it.int
  else:
    assert not hasMultipleCandidates

  if req.kind in {DisappearColor, DisappearCount, Chain, ChainClear,
                  DisappearColorSametime, DisappearCountSametime,
                  DisappearPlace, DisappearConnect}:
    result =
      if hasMultipleCandidates: req.number.get in nowNums
      else: req.number.get == nowNum
  else:
    result =
      if hasMultipleCandidates: nowNums.anyIt it >= req.number.get
      else: nowNum >= req.number.get

func mark[
    F: TsuField or WaterField,
    M: type(environment.move) or type(environment.moveWithRoughTracking) or
    type(environment.moveWithDetailTracking) or
    type(environment.moveWithFullTracking)](
      nazo: NazoPuyo[F], positions: Positions, moveFn: M): MarkResult
    {.inline.} =
  ## Marks the positions.
  {.push warning[ProveInit]:off.}
  var
    disappearColors =
      if nazo.requirement.kind in {DisappearColor, DisappearColorMore}:
        some set[ColorPuyo]({})
      else: none set[ColorPuyo]
    disappearCount =
      if nazo.requirement.kind in {DisappearCount, DisappearCountMore}:
        some 0.Natural
      else: none Natural
    nazo2 = nazo
    skipped = false
  {.pop.}

  for pos in positions:
    # skip position
    if pos.isNone:
      skipped = true
      continue
    if skipped:
      return SkipMove

    # impossible move
    if pos.get in nazo2.environment.field.invalidPositions:
      return ImpossibleMove

    let moveResult = nazo2.environment.moveFn(pos.get, false)

    # cumulative color
    if disappearColors.isSome:
      for color in ColorPuyo:
        if moveResult.cellCount(color) > 0:
          disappearColors.get.incl color

    # cumulative num
    if disappearCount.isSome:
      let newCount = case nazo.requirement.color.get
      of RequirementColor.All:
        moveResult.puyoCount
      of RequirementColor.Color:
        moveResult.colorCount
      of RequirementColor.Garbage:
        moveResult.garbageCount
      else:
        moveResult.cellCount RequirementColorToCell[nazo.requirement.color.get]

      disappearCount.get.inc newCount

    # check requirement
    if nazo.requirement.accept(moveResult, nazo2.environment.field,
                               disappearColors, disappearCount):
      return Accept

    # dead
    if nazo2.environment.field.isDead:
      return Dead

  result = WrongAnswer

func mark*(nazo: NazoPuyo, positions: Positions): MarkResult {.inline.} =
  ## Marks the positions.
  case nazo.requirement.kind
  of Clear, Chain, ChainMore, ChainClear, ChainMoreClear:
    nazo.mark(positions, environment.move[nazo.F])
  of DisappearColor, DisappearColorMore, DisappearCount, DisappearCountMore:
    nazo.mark(positions, environment.moveWithRoughTracking[nazo.F])
  of DisappearColorSametime, DisappearColorMoreSametime,
      DisappearCountSametime, DisappearCountMoreSametime:
    nazo.mark(positions, environment.moveWithDetailTracking[nazo.F])
  of DisappearPlace, DisappearPlaceMore, DisappearConnect, DisappearConnectMore:
    nazo.mark(positions, environment.moveWithFullTracking[nazo.F])
