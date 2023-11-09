## This module implements marking.
##

{.experimental: "strictDefs".}

import std/[options, sequtils, tables]
import ./[nazopuyo]
import ../corepkg/[cell, environment, field, moveresult as mrModule, position]

type MarkResult* = enum
  ## Marking result.
  Accept
  WrongAnswer
  Dead
  ImpossibleMove
  SkipMove
  NotSupport

const ReqColorToPuyo = {
  RequirementColor.Garbage: Cell.Garbage.Puyo,
  RequirementColor.Red: Cell.Red.Puyo,
  RequirementColor.Green: Cell.Green.Puyo,
  RequirementColor.Blue: Cell.Blue.Puyo,
  RequirementColor.Yellow: Cell.Yellow.Puyo,
  RequirementColor.Purple: Cell.Purple.Puyo}.toTable

# ------------------------------------------------
# Support
# ------------------------------------------------

func isSupported*(req: Requirement): bool {.inline.} =
  ## Returns `true` if the requirement is supported.
  req.kind notin {
    DisappearPlace, DisappearPlaceMore, DisappearConnect,
    DisappearConnectMore} or req.color != some RequirementColor.Garbage

# ------------------------------------------------
# Common
# ------------------------------------------------

template markTmpl[
    F: TsuField or WaterField,
    M: type(environment.move) or type(environment.moveWithRoughTracking) or
    type(environment.moveWithDetailTracking) or
    type(environment.moveWithFullTracking)](
      nazo: NazoPuyo[F], positions: Positions, moveFn: M, clear: static bool,
      solvedBody: untyped): untyped =
  ## Marking framework.
  ##
  ## Requirement-specific marking should be implemented in `solvedBody`.
  ## In `solvedBody`, `Accept` need to be returned if the requirement is
  ## satisfied.
  var
    nazo2 = nazo
    skipped = false

  for pos in positions:
    # skip
    if pos.isNone:
      skipped = true
      continue
    if skipped:
      return SkipMove

    # impossible move
    if pos.get in nazo2.environment.field.invalidPositions:
      return ImpossibleMove

    let moveResult {.inject.} = moveFn(nazo2.environment, pos.get, false)

    # clear
    when clear:
      let fieldCount = case nazo.requirement.color.get
      of RequirementColor.All: nazo2.environment.field.puyoCount
      of RequirementColor.Garbage: nazo2.environment.field.garbageCount
      of RequirementColor.Color: nazo2.environment.field.colorCount
      else: nazo2.environment.field.puyoCount ReqColorToPuyo[
        nazo.requirement.color.get]

      if fieldCount == 0:
        solvedBody
    else:
      solvedBody

    # dead
    if nazo2.environment.field.isDead:
      return Dead

  return WrongAnswer

func solved[F: TsuField or WaterField, T: SomeNumber or Natural](
    nazo: NazoPuyo[F], number: T, exact: static bool): bool {.inline.} =
  ## Returns `true` if the nazo puyo is solved.
  when exact: number == nazo.requirement.number.get
  else: number >= nazo.requirement.number.get

func solved[F: TsuField or WaterField, T: SomeNumber or Natural](
    nazo: NazoPuyo[F], numbers: openArray[T], exact: static bool): bool
    {.inline.} =
  ## Returns `true` if the nazo puyo is solved.
  when exact: nazo.requirement.number.get in numbers
  else: numbers.anyIt it >= nazo.requirement.number.get

# ------------------------------------------------
# Requirement-specific Marking
# ------------------------------------------------

func markClear[F: TsuField or WaterField](
    nazo: NazoPuyo[F], positions: Positions): MarkResult
    {.inline.} =
  ## Marks the positions with `Clear` requirement.
  nazo.markTmpl(positions, environment.move[F], true):
    discard moveResult # HACK: remove warning
    return Accept

func markDisappearColor[F: TsuField or WaterField](
    nazo: NazoPuyo[F], positions: Positions, exact: static bool): MarkResult
    {.inline.} =
  ## Marks the positions with `DisappearColor[More]` requirement.
  var disappearedColors = set[ColorPuyo]({})

  nazo.markTmpl(positions, environment.moveWithRoughTracking[F], false):
    disappearedColors.incl moveResult.colors

    if nazo.solved(disappearedColors.card, exact):
      return Accept

func markDisappearCount[F: TsuField or WaterField](
    nazo: NazoPuyo[F], positions: Positions, exact: static bool): MarkResult
    {.inline.} =
  ## Marks the positions with `DisappearCount[More]` requirement.
  var count = 0

  nazo.markTmpl(positions, environment.moveWithRoughTracking[F], false):
    count.inc case nazo.requirement.color.get
    of RequirementColor.All: moveResult.puyoCount
    of RequirementColor.Color: moveResult.colorCount
    else: moveResult.puyoCount ReqColorToPuyo[nazo.requirement.color.get]

    if nazo.solved(count, exact):
      return Accept

func markChain[F: TsuField or WaterField](
    nazo: NazoPuyo[F], positions: Positions, exact: static bool): MarkResult
    {.inline.} =
  ## Marks the positions with `Chain[More]` requirement.
  nazo.markTmpl(positions, environment.move[F], false):
    if nazo.solved(moveResult.chainCount, exact):
      return Accept

func markChainClear[F: TsuField or WaterField](
    nazo: NazoPuyo[F], positions: Positions, exact: static bool): MarkResult
    {.inline.} =
  ## Marks the positions with `Chain[More]Clear` requirement.
  nazo.markTmpl(positions, environment.move[F], true):
    if nazo.solved(moveResult.chainCount, exact):
      return Accept

func markDisappearColorSametime[F: TsuField or WaterField](
    nazo: NazoPuyo[F], positions: Positions, exact: static bool): MarkResult
    {.inline.} =
  ## Marks the positions with `DisappearColor[More]Sametime` requirement.
  nazo.markTmpl(positions, environment.moveWithDetailTracking[F], false):
    if nazo.solved(moveResult.colorsSeq.mapIt it.card , exact):
      return Accept

func markDisappearCountSametime[F: TsuField or WaterField](
    nazo: NazoPuyo[F], positions: Positions, exact: static bool): MarkResult
    {.inline.} =
  ## Marks the positions with `DisappearCount[More]Sametime` requirement.
  nazo.markTmpl(positions, environment.moveWithDetailTracking[F], false):
    let counts = case nazo.requirement.color.get
    of RequirementColor.All: moveResult.puyoCounts
    of RequirementColor.Color: moveResult.colorCounts
    else: moveResult.puyoCounts ReqColorToPuyo[nazo.requirement.color.get]

    if nazo.solved(counts, exact):
      return Accept

func markDisappearPlace[F: TsuField or WaterField](
    nazo: NazoPuyo[F], positions: Positions, exact: static bool): MarkResult
    {.inline.} =
  ## Marks the positions with `DisappearPlace[More]Sametime` requirement.
  nazo.markTmpl(positions, environment.moveWithFullTracking[F], false):
    let places = case nazo.requirement.color.get
    of RequirementColor.All, RequirementColor.Color: moveResult.colorPlaces
    else: moveResult.colorPlaces ReqColorToPuyo[nazo.requirement.color.get]

    if nazo.solved(places, exact):
      return Accept

func markDisappearConnect[F: TsuField or WaterField](
    nazo: NazoPuyo[F], positions: Positions, exact: static bool): MarkResult
    {.inline.} =
  ## Marks the positions with `DisappearConnect[More]Sametime` requirement.
  nazo.markTmpl(positions, environment.moveWithFullTracking[F], false):
    let connects = case nazo.requirement.color.get
    of RequirementColor.All, RequirementColor.Color: moveResult.colorConnects
    else: moveResult.colorConnects ReqColorToPuyo[nazo.requirement.color.get]

    if nazo.solved(connects, exact):
      return Accept

func mark*[F: TsuField or WaterField](nazo: NazoPuyo[F], positions: Positions):
    MarkResult {.inline.} =
  ## Marks the positions.
  if not nazo.requirement.isSupported:
    return NotSupport

  result = case nazo.requirement.kind
  of Clear: nazo.markClear positions
  of DisappearColor: nazo.markDisappearColor(positions, true)
  of DisappearColorMore: nazo.markDisappearColor(positions, false)
  of DisappearCount: nazo.markDisappearCount(positions, true)
  of DisappearCountMore: nazo.markDisappearCount(positions, false)
  of Chain: nazo.markChain(positions, true)
  of ChainMore: nazo.markChain(positions, false)
  of ChainClear: nazo.markChainClear(positions, true)
  of ChainMoreClear: nazo.markChainClear(positions, false)
  of DisappearColorSametime: nazo.markDisappearColorSametime(positions, true)
  of DisappearColorMoreSametime:
    nazo.markDisappearColorSametime(positions, false)
  of DisappearCountSametime: nazo.markDisappearCountSametime(positions, true)
  of DisappearCountMoreSametime:
    nazo.markDisappearCountSametime(positions, false)
  of DisappearPlace: nazo.markDisappearPlace(positions, true)
  of DisappearPlaceMore: nazo.markDisappearPlace(positions, false)
  of DisappearConnect: nazo.markDisappearConnect(positions, true)
  of DisappearConnectMore: nazo.markDisappearConnect(positions, false)
