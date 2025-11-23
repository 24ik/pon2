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

func isSatisfied(goal: Goal, val: int, exact: static bool): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  when exact:
    val == goal.val
  else:
    val >= goal.val

func isSatisfied(
    goal: Goal, vals: openArray[int], exact: static bool
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  when exact:
    goal.val in vals
  else:
    vals.anyIt it >= goal.val

template expandColor(
    isSatisfiedIdent: untyped, goal: Goal, moveResult: MoveResult, exact: static bool
): untyped =
  case goal.color
  of All:
    goal.isSatisfiedIdent(moveResult, exact, All)
  of GoalColor.Red:
    goal.isSatisfiedIdent(moveResult, exact, GoalColor.Red)
  of GoalColor.Green:
    goal.isSatisfiedIdent(moveResult, exact, GoalColor.Green)
  of GoalColor.Blue:
    goal.isSatisfiedIdent(moveResult, exact, GoalColor.Blue)
  of GoalColor.Yellow:
    goal.isSatisfiedIdent(moveResult, exact, GoalColor.Yellow)
  of GoalColor.Purple:
    goal.isSatisfiedIdent(moveResult, exact, GoalColor.Purple)
  of Garbages:
    goal.isSatisfiedIdent(moveResult, exact, Garbages)
  of Colors:
    goal.isSatisfiedIdent(moveResult, exact, Colors)

template expandExact(
    isSatisfiedIdent: untyped, goal: Goal, moveResult: MoveResult
): untyped =
  if goal.exact:
    goal.isSatisfiedIdent(moveResult, true)
  else:
    goal.isSatisfiedIdent(moveResult, false)

# ------------------------------------------------
# Chain
# ------------------------------------------------

func isSatisfiedChain*(
    goal: Goal, moveResult: MoveResult, exact: static bool
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  goal.isSatisfied(moveResult.chainCount, exact)

func isSatisfiedChain*(goal: Goal, moveResult: MoveResult): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  isSatisfiedChain.expandExact(goal, moveResult)

# ------------------------------------------------
# Color
# ------------------------------------------------

func isSatisfiedColor*(
    goal: Goal, moveResult: MoveResult, exact: static bool
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  goal.isSatisfied(moveResult.colorsSeq.mapIt it.card, exact)

func isSatisfiedColor*(goal: Goal, moveResult: MoveResult): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  isSatisfiedColor.expandExact(goal, moveResult)

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
    goal: Goal, moveResult: MoveResult, exact: static bool, color: static GoalColor
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  let counts = staticCase:
    case color
    of All:
      moveResult.puyoCounts
    of Garbages:
      moveResult.garbagesCounts
    of Colors:
      moveResult.colorPuyoCounts
    else:
      moveResult.cellCounts GoalColorToCell[color]

  goal.isSatisfied(counts, exact)

func isSatisfiedCount*(
    goal: Goal, moveResult: MoveResult, exact: static bool
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  isSatisfiedCount.expandColor goal, moveResult, exact

func isSatisfiedCount*(goal: Goal, moveResult: MoveResult): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  isSatisfiedCount.expandExact goal, moveResult

# ------------------------------------------------
# Place
# ------------------------------------------------

func isSatisfiedPlace*(
    goal: Goal, moveResult: MoveResult, exact: static bool, color: static GoalColor
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  let places = staticCase:
    case color
    of All, Colors:
      moveResult.placeCounts
    else:
      moveResult.placeCounts GoalColorToCell[color]

  goal.isSatisfied(places.unsafeValue, exact)

func isSatisfiedPlace*(
    goal: Goal, moveResult: MoveResult, exact: static bool
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  isSatisfiedPlace.expandColor goal, moveResult, exact

func isSatisfiedPlace*(goal: Goal, moveResult: MoveResult): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  isSatisfiedPlace.expandExact goal, moveResult

# ------------------------------------------------
# Connection
# ------------------------------------------------

func isSatisfiedConnection*(
    goal: Goal, moveResult: MoveResult, exact: static bool, color: static GoalColor
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  let connections = staticCase:
    case color
    of All, Colors:
      moveResult.connectionCounts
    else:
      moveResult.connectionCounts GoalColorToCell[color]

  goal.isSatisfied(connections.unsafeValue, exact)

func isSatisfiedConnection*(
    goal: Goal, moveResult: MoveResult, exact: static bool
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  isSatisfiedConnection.expandColor goal, moveResult, exact

func isSatisfiedConnection*(
    goal: Goal, moveResult: MoveResult
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  isSatisfiedConnection.expandExact goal, moveResult

# ------------------------------------------------
# AccumColor
# ------------------------------------------------

func isSatisfiedAccumColor*(
    goal: Goal, colors: set[Cell], exact: static bool
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  goal.isSatisfied(colors.card, exact)

func isSatisfiedAccumColor*(goal: Goal, colors: set[Cell]): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  if goal.exact:
    goal.isSatisfiedAccumColor(colors, true)
  else:
    goal.isSatisfiedAccumColor(colors, false)

# ------------------------------------------------
# AccumCount
# ------------------------------------------------

func isSatisfiedAccumCount*(
    goal: Goal, count: int, exact: static bool
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  goal.isSatisfied(count, exact)

func isSatisfiedAccumCount*(goal: Goal, count: int): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  if goal.exact:
    goal.isSatisfiedAccumCount(count, true)
  else:
    goal.isSatisfiedAccumCount(count, false)
