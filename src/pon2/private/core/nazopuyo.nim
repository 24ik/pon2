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

template isSatisfied(goal: Goal, iter, body: untyped): bool =
  ## Returns `true` if the goal is satisfied.
  let main = goal.mainOpt.unsafeValue

  case main.operator
  of Exact:
    iter.anyIt body == main.val
  of AtLeast:
    iter.anyIt body >= main.val

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
  goal.isSatisfied(moveResult.colorsSeq, it.card)

# ------------------------------------------------
# Count
# ------------------------------------------------

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
        moveResult.coloredPuyoCounts
      else:
        moveResult.cellCounts main.color.ord.Cell

  goal.isSatisfied(counts, it)

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
        moveResult.placeCounts.unsafeValue
      else:
        moveResult.placeCounts(main.color.ord.Cell).unsafeValue

  goal.isSatisfied(places, it)

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
        moveResult.connectionCounts.unsafeValue
      else:
        moveResult.connectionCounts(main.color.ord.Cell).unsafeValue

  goal.isSatisfied(connections, it)

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
