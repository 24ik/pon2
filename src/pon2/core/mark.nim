## This module implements Nazo Puyo marking.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[deques, options]
import ./[cell, field, goal, moveresult, nazopuyo, puyopuyo, step]
import ../private/[assign3, results2]
import ../private/core/[mark]

type MarkResult* = enum
  ## Marking result.
  Accept = "クリア！"
  WrongAnswer = "　"
  Dead = "ばたんきゅ〜"
  InvalidMove = "不可能な設置"
  SkipMove = "設置スキップ"
  NotSupport = "未対応の条件"

const
  DummyCell = Cell.low
  GoalColorToCell: array[GoalColor, Cell] = [
    DummyCell, Cell.Red, Cell.Green, Cell.Blue, Cell.Yellow, Cell.Purple, DummyCell,
    DummyCell,
  ]

func mark*[F: TsuField or WaterField](nazo: NazoPuyo[F]): MarkResult {.inline.} =
  ## Marks the steps in the Nazo Puyo.
  ## This function requires that the field is settled.
  if not nazo.goal.isSupported:
    return NotSupport

  let calcConn = nazo.goal.kind in {Place, PlaceMore, Conn, ConnMore}
  var
    puyoPuyo = nazo.puyoPuyo
    skipped = false
    popColors = set[Cell]({}) # used by AccColor[More]
    popCnt = 0 # used by AccCnt[More]

  while puyoPuyo.steps.len > 0:
    let step = puyoPuyo.steps.peekFirst

    # check skip, invalid
    case step.kind
    of PairPlacement:
      if step.optPlacement.isOk:
        if skipped:
          return SkipMove
        if step.optPlacement.expect in puyoPuyo.field.invalidPlacements:
          return InvalidMove
      else:
        skipped = true
    of StepKind.Garbages:
      discard

    let moveRes = puyoPuyo.move calcConn

    # update accumulative results
    case nazo.goal.kind
    of AccColor, AccColorMore:
      popColors.incl moveRes.colors
    of AccCnt, AccCntMore:
      let addCnt =
        case nazo.goal.optColor.expect
        of All:
          moveRes.puyoCnt
        of GoalColor.Garbages:
          moveRes.garbagesCnt
        of Colors:
          moveRes.colorPuyoCnt
        else:
          moveRes.cellCnt GoalColorToCell[nazo.goal.optColor.expect]

      popCnt.inc addCnt
    else:
      discard

    # check clear
    var satisfied =
      if nazo.goal.kind in {Clear, ClearChain, ClearChainMore}:
        let fieldCnt =
          case nazo.goal.optColor.expect
          of All:
            puyoPuyo.field.puyoCnt
          of GoalColor.Garbages:
            puyoPuyo.field.garbagesCnt
          of Colors:
            puyoPuyo.field.colorPuyoCnt
          else:
            puyoPuyo.field.cellCnt GoalColorToCell[nazo.goal.optColor.expect]

        fieldCnt == 0
      else:
        true

    # check kind-specific
    satisfied.assign satisfied and (
      case nazo.goal.kind
      of Clear:
        true
      of AccColor:
        nazo.goal.isSatisfiedAccColor(popColors, AccColor)
      of AccColorMore:
        nazo.goal.isSatisfiedAccColor(popColors, AccColorMore)
      of AccCnt:
        nazo.goal.isSatisfiedAccCnt(popCnt, AccCnt)
      of AccCntMore:
        nazo.goal.isSatisfiedAccCnt(popCnt, AccCntMore)
      of Chain:
        nazo.goal.isSatisfiedChain(moveRes, Chain)
      of ChainMore:
        nazo.goal.isSatisfiedChain(moveRes, ChainMore)
      of ClearChain:
        nazo.goal.isSatisfiedChain(moveRes, ClearChain)
      of ClearChainMore:
        nazo.goal.isSatisfiedChain(moveRes, ClearChainMore)
      of Color:
        nazo.goal.isSatisfiedColor(moveRes, Color)
      of ColorMore:
        nazo.goal.isSatisfiedColor(moveRes, ColorMore)
      of Cnt:
        nazo.goal.isSatisfiedCnt(moveRes, Cnt)
      of CntMore:
        nazo.goal.isSatisfiedCnt(moveRes, CntMore)
      of Place:
        nazo.goal.isSatisfiedPlace(moveRes, Place)
      of PlaceMore:
        nazo.goal.isSatisfiedPlace(moveRes, PlaceMore)
      of Conn:
        nazo.goal.isSatisfiedConn(moveRes, Conn)
      of ConnMore:
        nazo.goal.isSatisfiedConn(moveRes, ConnMore)
    )

    if satisfied:
      return Accept

    # check dead
    if puyoPuyo.field.isDead:
      return Dead

  return WrongAnswer
