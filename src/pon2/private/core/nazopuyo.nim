## This module implements helpers for Nazo Puyo marking.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils]
import ../[macros, results2]
import ../../core/[cell, goal, moveresult]

# ------------------------------------------------
# Common
# ------------------------------------------------

const ExactKinds =
  {AccumColor, AccumCount, Chain, ClearChain, Color, Count, Place, Connection}

func isSatisfied(goal: Goal, val: int, kind: static GoalKind): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  when kind in ExactKinds:
    val == goal.optVal.unsafeValue
  else:
    val >= goal.optVal.unsafeValue

func isSatisfied(
    goal: Goal, vals: openArray[int], kind: static GoalKind
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  when kind in ExactKinds:
    goal.optVal.unsafeValue in vals
  else:
    vals.anyIt it >= goal.optVal.unsafeValue

template expandColor(
    isSatisfiedIdent: untyped, goal: Goal, moveRes: MoveResult, kind: static GoalKind
): untyped =
  case goal.optColor.unsafeValue
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
# AccumColor
# ------------------------------------------------

func isSatisfiedAccumColor*(
    goal: Goal, colors: set[Cell], kind: static GoalKind
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  goal.isSatisfied(colors.card, kind)

# ------------------------------------------------
# AccumCount
# ------------------------------------------------

func isSatisfiedAccumCount*(
    goal: Goal, count: int, kind: static GoalKind
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  goal.isSatisfied(count, kind)

# ------------------------------------------------
# Chain
# ------------------------------------------------

func isSatisfiedChain*(
    goal: Goal, moveRes: MoveResult, kind: static GoalKind
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  goal.isSatisfied(moveRes.chainCount, kind)

# ------------------------------------------------
# Color
# ------------------------------------------------

func isSatisfiedColor*(
    goal: Goal, moveRes: MoveResult, kind: static GoalKind
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  goal.isSatisfied(moveRes.colorsSeq.mapIt it.card, kind)

# ------------------------------------------------
# Count
# ------------------------------------------------

const
  DummyCell = Cell.low
  GoalColorToCell: array[GoalColor, Cell] = [
    DummyCell, Cell.Red, Cell.Green, Cell.Blue, Cell.Yellow, Cell.Purple, DummyCell,
    DummyCell,
  ]

func isSatisfiedCount*(
    goal: Goal, moveRes: MoveResult, kind: static GoalKind, color: static GoalColor
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  let counts = staticCase:
    case color
    of All:
      moveRes.puyoCounts
    of Garbages:
      moveRes.garbagesCounts
    of Colors:
      moveRes.colorPuyoCounts
    else:
      moveRes.cellCounts GoalColorToCell[color]

  goal.isSatisfied(counts, kind)

func isSatisfiedCount*(
    goal: Goal, moveRes: MoveResult, kind: static GoalKind
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  isSatisfiedCount.expandColor goal, moveRes, kind

# ------------------------------------------------
# Place
# ------------------------------------------------

func isSatisfiedPlace*(
    goal: Goal, moveRes: MoveResult, kind: static GoalKind, color: static GoalColor
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  let places = staticCase:
    case color
    of All, Colors:
      moveRes.placeCounts
    else:
      moveRes.placeCounts GoalColorToCell[color]

  goal.isSatisfied(places.unsafeValue, kind)

func isSatisfiedPlace*(
    goal: Goal, moveRes: MoveResult, kind: static GoalKind
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  isSatisfiedPlace.expandColor goal, moveRes, kind

# ------------------------------------------------
# Connection
# ------------------------------------------------

func isSatisfiedConnection*(
    goal: Goal, moveRes: MoveResult, kind: static GoalKind, color: static GoalColor
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  let connections = staticCase:
    case color
    of All, Colors:
      moveRes.connectionCounts
    else:
      moveRes.connectionCounts GoalColorToCell[color]

  goal.isSatisfied(connections.unsafeValue, kind)

func isSatisfiedConnection*(
    goal: Goal, moveRes: MoveResult, kind: static GoalKind
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  isSatisfiedConnection.expandColor goal, moveRes, kind
