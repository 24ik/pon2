## This module implements Nazo Puyo marking.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[options, tables]
import ./[cell, field, moveresult, nazopuyo, position, puyopuyo, requirement]
import ../private/core/[mark]

type MarkResult* = enum
  ## Marking result.
  Accept
  WrongAnswer
  Dead
  ImpossibleMove
  SkipMove
  NotSupport

# ------------------------------------------------
# Mark
# ------------------------------------------------

const ReqColorToPuyo = {
  RequirementColor.Garbage: Cell.Garbage.Puyo,
  RequirementColor.Red: Cell.Red.Puyo,
  RequirementColor.Green: Cell.Green.Puyo,
  RequirementColor.Blue: Cell.Blue.Puyo,
  RequirementColor.Yellow: Cell.Yellow.Puyo,
  RequirementColor.Purple: Cell.Purple.Puyo
}.toTable

func mark*[F: TsuField or WaterField](nazo: NazoPuyo[F]): MarkResult {.inline.} =
  ## Marks the positions.
  if not nazo.requirement.isSupported:
    return NotSupport

  var
    nazo2 = nazo
    skipped = false
    disappearColors = set[ColorPuyo]({}) # used for DisappearColor
    disappearCount = 0 # used for DisappearCount

  let moveFn =
    case nazo.requirement.kind
    of Clear, Chain, ChainMore:
      puyopuyo.move[F]
    of DisappearColor, DisappearColorMore, DisappearCount, DisappearCountMore,
        ChainClear, ChainMoreClear:
      puyopuyo.moveWithRoughTracking[F]
    of DisappearColorSametime, DisappearColorMoreSametime, DisappearCountSametime,
        DisappearCountMoreSametime:
      puyopuyo.moveWithDetailTracking[F]
    of DisappearPlace, DisappearPlaceMore, DisappearConnect, DisappearConnectMore:
      puyopuyo.moveWithFullTracking[F]

  for (_, pos) in nazo.puyoPuyo.pairsPositions:
    # skip
    if pos == Position.None:
      skipped = true
    if skipped:
      return SkipMove

    # impossible move
    if pos in nazo2.puyoPuyo.field.invalidPositions:
      return ImpossibleMove

    # move and update intermediate result
    let moveRes = nazo2.puyoPuyo.moveFn pos
    case nazo.requirement.kind
    of DisappearColor, DisappearColorMore:
      disappearColors.incl moveRes.colors
    of DisappearCount, DisappearCountMore:
      let addCount =
        case nazo.requirement.color
        of RequirementColor.All:
          moveRes.puyoCount
        of RequirementColor.Color:
          moveRes.colorCount
        of RequirementColor.Garbage:
          moveRes.garbageCount
        else:
          moveRes.puyoCount ReqColorToPuyo[nazo.requirement.color]

      disappearCount.inc addCount
    else:
      discard

    # check if the field is clear
    if nazo.requirement.kind in {Clear, ChainClear, ChainMoreClear}:
      let fieldCount =
        case nazo.requirement.color
        of RequirementColor.All:
          nazo2.puyoPuyo.field.puyoCount
        of RequirementColor.Garbage:
          nazo2.puyoPuyo.field.garbageCount
        of RequirementColor.Color:
          nazo2.puyoPuyo.field.colorCount
        else:
          nazo2.puyoPuyo.field.puyoCount ReqColorToPuyo[nazo.requirement.color]

      if fieldCount != 0:
        continue

    # check if the requirement is satisfied
    let satisfied =
      case nazo.requirement.kind
      of Clear:
        true
      of DisappearColor:
        nazo.requirement.disappearColorSatisfied(disappearColors, DisappearColor)
      of DisappearColorMore:
        nazo.requirement.disappearColorSatisfied(disappearColors, DisappearColorMore)
      of DisappearCount:
        nazo.requirement.disappearCountSatisfied(disappearCount, DisappearCount)
      of DisappearCountMore:
        nazo.requirement.disappearCountSatisfied(disappearCount, DisappearCountMore)
      of Chain:
        nazo.requirement.chainSatisfied(moveRes, Chain)
      of ChainMore:
        nazo.requirement.chainSatisfied(moveRes, ChainMore)
      of ChainClear:
        nazo.requirement.chainSatisfied(moveRes, ChainClear)
      of ChainMoreClear:
        nazo.requirement.chainSatisfied(moveRes, ChainMoreClear)
      of DisappearColorSametime:
        nazo.requirement.disappearColorSametimeSatisfied(
          moveRes, DisappearColorSametime
        )
      of DisappearColorMoreSametime:
        nazo.requirement.disappearColorSametimeSatisfied(
          moveRes, DisappearColorMoreSametime
        )
      of DisappearCountSametime:
        nazo.requirement.disappearCountSametimeSatisfied(
          moveRes, DisappearCountSametime
        )
      of DisappearCountMoreSametime:
        nazo.requirement.disappearCountSametimeSatisfied(
          moveRes, DisappearCountMoreSametime
        )
      of DisappearPlace:
        nazo.requirement.disappearPlaceSatisfied(moveRes, DisappearPlace)
      of DisappearPlaceMore:
        nazo.requirement.disappearPlaceSatisfied(moveRes, DisappearPlaceMore)
      of DisappearConnect:
        nazo.requirement.disappearConnectSatisfied(moveRes, DisappearConnect)
      of DisappearConnectMore:
        nazo.requirement.disappearConnectSatisfied(moveRes, DisappearConnectMore)

    if satisfied:
      return Accept

    # dead
    if nazo2.puyoPuyo.field.isDead:
      return Dead

  result = WrongAnswer
