## This module implements helpers for Nazo Puyo marking.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils]
import ../[macros2, results2]
import ../../core/[cell, goal, moveresult]

# ------------------------------------------------
# Common
# ------------------------------------------------

const ExactKinds = {AccColor, AccCnt, Chain, ClearChain, Color, Cnt, Place, Conn}

func isSatisfied(goal: Goal, val: int, kind: static GoalKind): bool {.inline.} =
  ## Returns `true` if the goal is satisfied.
  when kind in ExactKinds:
    val == goal.optVal.expect
  else:
    val >= goal.optVal.expect

func isSatisfied(
    goal: Goal, vals: openArray[int], kind: static GoalKind
): bool {.inline.} =
  ## Returns `true` if the goal is satisfied.
  when kind in ExactKinds:
    goal.optVal.expect in vals
  else:
    vals.anyIt it >= goal.optVal.expect

template expandColor(
    isSatisfiedIdent: untyped, goal: Goal, moveRes: MoveResult, kind: static GoalKind
): untyped =
  case goal.optColor.expect
  of All:
    goal.isSatisfiedIdent(moveRes, kind, All)
  of GoalColor.Red:
    goal.isSatisfiedIdent(moveRes, kind, GoalColor.Red)
  of GoalColor.Green:
    goal.isSatisfiedIdent(moveRes, kind, GoalColor.Green)
  of GoalColor.Blue:
    goal.isSatisfiedIdent(moveRes, kind, GoalColor.Blue)
  of GoalColor.Yellow:
    goal.isSatisfiedIdent(moveRes, kind, GoalColor.Yellow)
  of GoalColor.Purple:
    goal.isSatisfiedIdent(moveRes, kind, GoalColor.Purple)
  of Garbages:
    goal.isSatisfiedIdent(moveRes, kind, Garbages)
  of Colors:
    goal.isSatisfiedIdent(moveRes, kind, Colors)

# ------------------------------------------------
# AccColor
# ------------------------------------------------

func isSatisfiedAccColor*(
    goal: Goal, colors: set[Cell], kind: static GoalKind
): bool {.inline.} =
  ## Returns `true` if the goal is satisfied.
  goal.isSatisfied(colors.card, kind)

# ------------------------------------------------
# AccCnt
# ------------------------------------------------

func isSatisfiedAccCnt*(goal: Goal, cnt: int, kind: static GoalKind): bool {.inline.} =
  ## Returns `true` if the goal is satisfied.
  goal.isSatisfied(cnt, kind)

# ------------------------------------------------
# Chain
# ------------------------------------------------

func isSatisfiedChain*(
    goal: Goal, moveRes: MoveResult, kind: static GoalKind
): bool {.inline.} =
  ## Returns `true` if the goal is satisfied.
  goal.isSatisfied(moveRes.chainCnt, kind)

# ------------------------------------------------
# Color
# ------------------------------------------------

func isSatisfiedColor*(
    goal: Goal, moveRes: MoveResult, kind: static GoalKind
): bool {.inline.} =
  ## Returns `true` if the goal is satisfied.
  goal.isSatisfied(moveRes.colorsSeq.mapIt it.card, kind)

# ------------------------------------------------
# Cnt
# ------------------------------------------------

const
  DummyCell = Cell.low
  GoalColorToCell: array[GoalColor, Cell] = [
    DummyCell, Cell.Red, Cell.Green, Cell.Blue, Cell.Yellow, Cell.Purple, DummyCell,
    DummyCell,
  ]

func isSatisfiedCnt*(
    goal: Goal, moveRes: MoveResult, kind: static GoalKind, color: static GoalColor
): bool {.inline.} =
  ## Returns `true` if the goal is satisfied.
  let cnts = staticCase:
    case color
    of All:
      moveRes.puyoCnts
    of Garbages:
      moveRes.garbagesCnts
    of Colors:
      moveRes.colorPuyoCnts
    else:
      moveRes.cellCnts GoalColorToCell[color]

  goal.isSatisfied(cnts, kind)

func isSatisfiedCnt*(
    goal: Goal, moveRes: MoveResult, kind: static GoalKind
): bool {.inline.} =
  ## Returns `true` if the goal is satisfied.
  isSatisfiedCnt.expandColor goal, moveRes, kind

# ------------------------------------------------
# Place
# ------------------------------------------------

func isSatisfiedPlace*(
    goal: Goal, moveRes: MoveResult, kind: static GoalKind, color: static GoalColor
): bool {.inline.} =
  ## Returns `true` if the goal is satisfied.
  let places = staticCase:
    case color
    of All, Colors:
      moveRes.placeCnts
    else:
      moveRes.placeCnts GoalColorToCell[color]

  goal.isSatisfied(places.expect, kind)

func isSatisfiedPlace*(
    goal: Goal, moveRes: MoveResult, kind: static GoalKind
): bool {.inline.} =
  ## Returns `true` if the goal is satisfied.
  isSatisfiedPlace.expandColor goal, moveRes, kind

# ------------------------------------------------
# Conn
# ------------------------------------------------

func isSatisfiedConn*(
    goal: Goal, moveRes: MoveResult, kind: static GoalKind, color: static GoalColor
): bool {.inline.} =
  ## Returns `true` if the goal is satisfied.
  let conns = staticCase:
    case color
    of All, Colors:
      moveRes.connCnts
    else:
      moveRes.connCnts GoalColorToCell[color]

  goal.isSatisfied(conns.expect, kind)

func isSatisfiedConn*(
    goal: Goal, moveRes: MoveResult, kind: static GoalKind
): bool {.inline.} =
  ## Returns `true` if the goal is satisfied.
  isSatisfiedConn.expandColor goal, moveRes, kind
