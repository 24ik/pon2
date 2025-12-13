## This module implements helpers for Nazo Puyo marking.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils]
import ../../core/[cell, goal, moveresult]

# ------------------------------------------------
# Common
# ------------------------------------------------

func isSatisfied(goal: Goal, val: int): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  let main = goal.mainOpt.unsafeValue

  case main.operator
  of Exact:
    val == main.val
  of AtLeast:
    val >= main.val

func isSatisfied(goal: Goal, vals: openArray[int]): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  let main = goal.mainOpt.unsafeValue

  case main.operator
  of Exact:
    main.val in vals
  of AtLeast:
    vals.anyIt it >= main.val

# ------------------------------------------------
# Chain
# ------------------------------------------------

func isSatisfiedChain*(goal: Goal, moveResult: MoveResult): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  goal.isSatisfied moveResult.chainCount

# ------------------------------------------------
# Color
# ------------------------------------------------

func isSatisfiedColor*(goal: Goal, moveResult: MoveResult): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  goal.isSatisfied moveResult.colorsSeq.mapIt it.card

# ------------------------------------------------
# Count
# ------------------------------------------------

const
  DummyCell = Cell.low
  GoalColorToCell: array[GoalColor, Cell] = [
    DummyCell, Cell.Red, Cell.Green, Cell.Blue, Cell.Yellow, Cell.Purple, DummyCell,
    DummyCell,
  ]

func isSatisfiedCount*(goal: Goal, moveResult: MoveResult): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  let
    main = goal.mainOpt.unsafeValue
    counts =
      case main.color
      of All:
        moveResult.puyoCounts
      of Nuisance:
        moveResult.nuisancePuyoCounts
      of Colored:
        moveResult.colorPuyoCounts
      else:
        moveResult.cellCounts GoalColorToCell[main.color]

  goal.isSatisfied counts

# ------------------------------------------------
# Place
# ------------------------------------------------

func isSatisfiedPlace*(goal: Goal, moveResult: MoveResult): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  let
    main = goal.mainOpt.unsafeValue
    places =
      case main.color
      of All, Nuisance, Colored:
        moveResult.placeCounts
      else:
        moveResult.placeCounts GoalColorToCell[main.color]

  goal.isSatisfied places.unsafeValue

# ------------------------------------------------
# Connection
# ------------------------------------------------

func isSatisfiedConnection*(
    goal: Goal, moveResult: MoveResult
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  let
    main = goal.mainOpt.unsafeValue
    connections =
      case main.color
      of All, Nuisance, Colored:
        moveResult.connectionCounts
      else:
        moveResult.connectionCounts GoalColorToCell[main.color]

  goal.isSatisfied connections.unsafeValue

# ------------------------------------------------
# AccumColor
# ------------------------------------------------

func isSatisfiedAccumColor*(goal: Goal, colors: set[Cell]): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  goal.isSatisfied colors.card

# ------------------------------------------------
# AccumCount
# ------------------------------------------------

func isSatisfiedAccumCount*(goal: Goal, count: int): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  goal.isSatisfied count
