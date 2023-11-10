## This module implements helper functions for marking.
##

{.experimental: "strictDefs".}

import std/[options, sequtils, tables]
import ../../nazopuyopkg/[nazopuyo]
import ../../corepkg/[cell, moveresult]

# ------------------------------------------------
# Common - Satisfy
# ------------------------------------------------

const ExactKinds = {DisappearColor, DisappearCount, Chain, ChainClear,
                    DisappearColorSametime, DisappearCountSametime,
                    DisappearPlace, DisappearConnect}

func satisfied[T: SomeNumber or Natural](
    req: Requirement, number: T, kind: static RequirementKind): bool
    {.inline.} =
  ## Returns `true` if the requirement is satisfied.
  assert req.kind == kind

  when kind in ExactKinds:
    number == req.number.get
  else:
    number >= req.number.get

func satisfied[T: SomeNumber or Natural](
    req: Requirement, numbers: openArray[T], kind: static RequirementKind): bool
    {.inline.} =
  ## Returns `true` if the requirement is satisfied.
  assert req.kind == kind

  when kind in ExactKinds:
    req.number.get in numbers
  else:
    numbers.anyIt it >= req.number.get

# ------------------------------------------------
# Requirement-specific
# ------------------------------------------------

const ReqColorToPuyo = {
  RequirementColor.Garbage: Cell.Garbage.Puyo,
  RequirementColor.Red: Cell.Red.Puyo,
  RequirementColor.Green: Cell.Green.Puyo,
  RequirementColor.Blue: Cell.Blue.Puyo,
  RequirementColor.Yellow: Cell.Yellow.Puyo,
  RequirementColor.Purple: Cell.Purple.Puyo}.toTable

func disappearColorSatisfied*(
    req: Requirement, colors: set[ColorPuyo],
    kind: static RequirementKind): bool {.inline.} =
  ## Returns `true` if the requirement satisfied.
  req.satisfied(colors.card, kind)
  
func disappearCountSatisfied*(
    req: Requirement, count: int, kind: static RequirementKind): bool
    {.inline.} =
  ## Returns `true` if the requirement satisfied.
  req.satisfied(count, kind)

func chainSatisfied*(
    req: Requirement, moveRes: MoveResult, kind: static RequirementKind): bool
    {.inline.} =
  ## Returns `true` if the requirement satisfied.
  req.satisfied(moveRes.chainCount, kind)

func disappearColorSametimeSatisfied*(
    req: Requirement, moveRes: DetailMoveResult,
    kind: static RequirementKind): bool {.inline.} =
  ## Returns `true` if the requirement satisfied.
  req.satisfied(moveRes.colorsSeq.mapIt it.card, kind)

func disappearCountSametimeSatisfied*(
    req: Requirement, moveRes: DetailMoveResult,
    kind: static RequirementKind): bool {.inline.} =
  ## Returns `true` if the requirement satisfied.
  let counts =
    if req.color.get == RequirementColor.All: moveRes.puyoCounts
    elif req.color.get == RequirementColor.Color: moveRes.colorCounts
    else: moveRes.puyoCounts ReqColorToPuyo[req.color.get]

  result = req.satisfied(counts, kind)

func disappearPlaceSatisfied*(
    req: Requirement, moveRes: FullMoveResult,
    kind: static RequirementKind): bool {.inline.} =
  ## Returns `true` if the requirement satisfied.
  let places =
    if req.color.get in {RequirementColor.All, RequirementColor.Color}:
      moveRes.colorPlaces
    else:
      moveRes.colorPlaces ReqColorToPuyo[req.color.get]

  result = req.satisfied(places, kind)

func disappearConnectSatisfied*(
    req: Requirement, moveRes: FullMoveResult,
    kind: static RequirementKind): bool {.inline.} =
  ## Returns `true` if the requirement satisfied.
  let connects =
    if req.color.get in {RequirementColor.All, RequirementColor.Color}:
      moveRes.colorConnects
    else:
      moveRes.colorConnects ReqColorToPuyo[req.color.get]

  result = req.satisfied(connects, kind)
