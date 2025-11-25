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

func isSatisfied(
    goal: Goal, val: int, valOperator: static GoalValOperator
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  staticCase:
    case valOperator
    of Exact:
      val == goal.val
    of AtLeast:
      val >= goal.val

func isSatisfied(
    goal: Goal, vals: openArray[int], valOperator: static GoalValOperator
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  staticCase:
    case valOperator
    of Exact:
      goal.val in vals
    of AtLeast:
      vals.anyIt it >= goal.val

template expandColor(
    isSatisfiedIdent: untyped,
    goal: Goal,
    moveResult: MoveResult,
    valOperator: static GoalValOperator,
): untyped =
  case goal.color
  of GoalColor.None:
    goal.isSatisfiedIdent(moveResult, valOperator, GoalColor.None)
  of All:
    goal.isSatisfiedIdent(moveResult, valOperator, All)
  of GoalColor.Red:
    goal.isSatisfiedIdent(moveResult, valOperator, GoalColor.Red)
  of GoalColor.Green:
    goal.isSatisfiedIdent(moveResult, valOperator, GoalColor.Green)
  of GoalColor.Blue:
    goal.isSatisfiedIdent(moveResult, valOperator, GoalColor.Blue)
  of GoalColor.Yellow:
    goal.isSatisfiedIdent(moveResult, valOperator, GoalColor.Yellow)
  of GoalColor.Purple:
    goal.isSatisfiedIdent(moveResult, valOperator, GoalColor.Purple)
  of Garbages:
    goal.isSatisfiedIdent(moveResult, valOperator, Garbages)
  of Colors:
    goal.isSatisfiedIdent(moveResult, valOperator, Colors)

template expandValOperator(
    isSatisfiedIdent: untyped, goal: Goal, moveResult: MoveResult
): untyped =
  case goal.valOperator
  of Exact:
    goal.isSatisfiedIdent(moveResult, Exact)
  of AtLeast:
    goal.isSatisfiedIdent(moveResult, AtLeast)

# ------------------------------------------------
# Chain
# ------------------------------------------------

func isSatisfiedChain*(
    goal: Goal, moveResult: MoveResult, valOperator: static GoalValOperator
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  goal.isSatisfied(moveResult.chainCount, valOperator)

func isSatisfiedChain*(goal: Goal, moveResult: MoveResult): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  isSatisfiedChain.expandValOperator(goal, moveResult)

# ------------------------------------------------
# Color
# ------------------------------------------------

func isSatisfiedColor*(
    goal: Goal, moveResult: MoveResult, valOperator: static GoalValOperator
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  goal.isSatisfied(moveResult.colorsSeq.mapIt it.card, valOperator)

func isSatisfiedColor*(goal: Goal, moveResult: MoveResult): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  isSatisfiedColor.expandValOperator(goal, moveResult)

# ------------------------------------------------
# Count
# ------------------------------------------------

const
  DummyCell = Cell.low
  GoalColorToCell: array[GoalColor, Cell] = [
    DummyCell, DummyCell, Cell.Red, Cell.Green, Cell.Blue, Cell.Yellow, Cell.Purple,
    DummyCell, DummyCell,
  ]

func isSatisfiedCount*(
    goal: Goal,
    moveResult: MoveResult,
    valOperator: static GoalValOperator,
    color: static GoalColor,
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  let counts = staticCase:
    case color
    of GoalColor.None, All:
      moveResult.puyoCounts
    of Garbages:
      moveResult.garbagesCounts
    of Colors:
      moveResult.colorPuyoCounts
    else:
      moveResult.cellCounts GoalColorToCell[color]

  goal.isSatisfied(counts, valOperator)

func isSatisfiedCount*(
    goal: Goal, moveResult: MoveResult, valOperator: static GoalValOperator
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  isSatisfiedCount.expandColor goal, moveResult, valOperator

func isSatisfiedCount*(goal: Goal, moveResult: MoveResult): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  isSatisfiedCount.expandValOperator goal, moveResult

# ------------------------------------------------
# Place
# ------------------------------------------------

func isSatisfiedPlace*(
    goal: Goal,
    moveResult: MoveResult,
    valOperator: static GoalValOperator,
    color: static GoalColor,
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  let places = staticCase:
    case color
    of GoalColor.None, All, Colors:
      moveResult.placeCounts
    else:
      moveResult.placeCounts GoalColorToCell[color]

  goal.isSatisfied(places.unsafeValue, valOperator)

func isSatisfiedPlace*(
    goal: Goal, moveResult: MoveResult, valOperator: static GoalValOperator
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  isSatisfiedPlace.expandColor goal, moveResult, valOperator

func isSatisfiedPlace*(goal: Goal, moveResult: MoveResult): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  isSatisfiedPlace.expandValOperator goal, moveResult

# ------------------------------------------------
# Connection
# ------------------------------------------------

func isSatisfiedConnection*(
    goal: Goal,
    moveResult: MoveResult,
    valOperator: static GoalValOperator,
    color: static GoalColor,
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  let connections = staticCase:
    case color
    of GoalColor.None, All, Colors:
      moveResult.connectionCounts
    else:
      moveResult.connectionCounts GoalColorToCell[color]

  goal.isSatisfied(connections.unsafeValue, valOperator)

func isSatisfiedConnection*(
    goal: Goal, moveResult: MoveResult, valOperator: static GoalValOperator
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  isSatisfiedConnection.expandColor goal, moveResult, valOperator

func isSatisfiedConnection*(
    goal: Goal, moveResult: MoveResult
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  isSatisfiedConnection.expandValOperator goal, moveResult

# ------------------------------------------------
# AccumColor
# ------------------------------------------------

func isSatisfiedAccumColor*(
    goal: Goal, colors: set[Cell], valOperator: static GoalValOperator
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  goal.isSatisfied(colors.card, valOperator)

func isSatisfiedAccumColor*(goal: Goal, colors: set[Cell]): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  case goal.valOperator
  of Exact:
    goal.isSatisfiedAccumColor(colors, Exact)
  of AtLeast:
    goal.isSatisfiedAccumColor(colors, AtLeast)

# ------------------------------------------------
# AccumCount
# ------------------------------------------------

func isSatisfiedAccumCount*(
    goal: Goal, count: int, valOperator: static GoalValOperator
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  goal.isSatisfied(count, valOperator)

func isSatisfiedAccumCount*(goal: Goal, count: int): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  case goal.valOperator
  of Exact:
    goal.isSatisfiedAccumCount(count, Exact)
  of AtLeast:
    goal.isSatisfiedAccumCount(count, AtLeast)
