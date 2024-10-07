## This module implements helper functions for Nazo Puyo marking.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[options, sequtils, tables]
import ../../core/[cell, moveresult, requirement]

# ------------------------------------------------
# Common
# ------------------------------------------------

const ExactKinds = {
  DisappearColor, DisappearCount, Chain, ChainClear, DisappearColorSametime,
  DisappearCountSametime, DisappearPlace, DisappearConnect,
}

func satisfied[T: SomeNumber or Natural](
    req: Requirement, number: T, kind: static RequirementKind
): bool {.inline.} =
  ## Returns `true` if the requirement is satisfied.
  assert req.kind == kind

  when kind in ExactKinds:
    number == req.number
  else:
    number >= req.number

func satisfied[T: SomeNumber or Natural](
    req: Requirement, numbers: openArray[T], kind: static RequirementKind
): bool {.inline.} =
  ## Returns `true` if the requirement is satisfied.
  assert req.kind == kind

  when kind in ExactKinds:
    req.number in numbers
  else:
    numbers.anyIt it >= req.number

# ------------------------------------------------
# DisappearColor
# ------------------------------------------------

func disappearColorSatisfied*(
    req: Requirement, colors: set[ColorPuyo], kind: static RequirementKind
): bool {.inline.} =
  ## Returns `true` if the requirement satisfied.
  req.satisfied(colors.card, kind)

# ------------------------------------------------
# DisappearCount
# ------------------------------------------------

func disappearCountSatisfied*(
    req: Requirement, count: int, kind: static RequirementKind
): bool {.inline.} =
  ## Returns `true` if the requirement satisfied.
  req.satisfied(count, kind)

# ------------------------------------------------
# Chain
# ------------------------------------------------

func chainSatisfied*(
    req: Requirement, moveRes: MoveResult, kind: static RequirementKind
): bool {.inline.} =
  ## Returns `true` if the requirement satisfied.
  req.satisfied(moveRes.chainCount, kind)

# ------------------------------------------------
# DisappearColorSametime
# ------------------------------------------------

func disappearColorSametimeSatisfied*(
    req: Requirement, moveRes: MoveResult, kind: static RequirementKind
): bool {.inline.} =
  ## Returns `true` if the requirement satisfied.
  req.satisfied(moveRes.colorsSeq.mapIt it.card, kind)

# ------------------------------------------------
# DisappearCountSametime
# ------------------------------------------------

const ReqColorToPuyo = {
  RequirementColor.Garbage: Cell.Garbage.Puyo,
  RequirementColor.Red: Cell.Red.Puyo,
  RequirementColor.Green: Cell.Green.Puyo,
  RequirementColor.Blue: Cell.Blue.Puyo,
  RequirementColor.Yellow: Cell.Yellow.Puyo,
  RequirementColor.Purple: Cell.Purple.Puyo,
}.toTable

func disappearCountSametimeSatisfied*(
    req: Requirement,
    moveRes: MoveResult,
    kind: static RequirementKind,
    color: static RequirementColor,
): bool {.inline.} =
  ## Returns `true` if the requirement satisfied.
  assert req.color == color

  let counts =
    when color == RequirementColor.All:
      moveRes.puyoCounts
    elif color == RequirementColor.Color:
      moveRes.colorCounts
    elif color == RequirementColor.Garbage:
      moveRes.garbageCounts
    else:
      moveRes.puyoCounts ReqColorToPuyo[color]

  result = req.satisfied(counts, kind)

func disappearCountSametimeSatisfied*(
    req: Requirement, moveRes: MoveResult, kind: static RequirementKind
): bool {.inline.} =
  ## Returns `true` if the requirement satisfied.
  let counts =
    case req.color
    of RequirementColor.All:
      moveRes.puyoCounts
    of RequirementColor.Color:
      moveRes.colorCounts
    of RequirementColor.Garbage:
      moveRes.garbageCounts
    else:
      moveRes.puyoCounts ReqColorToPuyo[req.color]

  result = req.satisfied(counts, kind)

# ------------------------------------------------
# DisappearPlace
# ------------------------------------------------

func disappearPlaceSatisfied*(
    req: Requirement,
    moveRes: MoveResult,
    kind: static RequirementKind,
    color: static RequirementColor,
): bool {.inline.} =
  ## Returns `true` if the requirement satisfied.
  assert req.color == color

  let places =
    when color in {RequirementColor.All, RequirementColor.Color}:
      moveRes.colorPlaces
    else:
      moveRes.colorPlaces ReqColorToPuyo[color]

  result = req.satisfied(places, kind)

func disappearPlaceSatisfied*(
    req: Requirement, moveRes: MoveResult, kind: static RequirementKind
): bool {.inline.} =
  ## Returns `true` if the requirement satisfied.
  let places =
    case req.color
    of RequirementColor.All, RequirementColor.Color:
      moveRes.colorPlaces
    else:
      moveRes.colorPlaces ReqColorToPuyo[req.color]

  result = req.satisfied(places, kind)

# ------------------------------------------------
# DisappearConnect
# ------------------------------------------------

func disappearConnectSatisfied*(
    req: Requirement,
    moveRes: MoveResult,
    kind: static RequirementKind,
    color: static RequirementColor,
): bool {.inline.} =
  ## Returns `true` if the requirement satisfied.
  assert req.color == color

  let connects =
    if color in {RequirementColor.All, RequirementColor.Color}:
      moveRes.colorConnects
    else:
      moveRes.colorConnects ReqColorToPuyo[color]

  result = req.satisfied(connects, kind)

func disappearConnectSatisfied*(
    req: Requirement, moveRes: MoveResult, kind: static RequirementKind
): bool {.inline.} =
  ## Returns `true` if the requirement satisfied.
  let connects =
    case req.color
    of RequirementColor.All, RequirementColor.Color:
      moveRes.colorConnects
    else:
      moveRes.colorConnects ReqColorToPuyo[req.color]

  result = req.satisfied(connects, kind)
