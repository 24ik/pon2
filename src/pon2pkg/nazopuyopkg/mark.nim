## This module implements marking.
##

{.experimental: "strictDefs".}

import std/[options, tables]
import ./[nazopuyo]
import ../corepkg/[cell, environment, field, moveresult as mrModule, position]
import ../private/nazopuyo/[mark]

type MarkResult* = enum
  ## Marking result.
  Accept
  WrongAnswer
  Dead
  ImpossibleMove
  SkipMove
  NotSupport

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

const ReqColorToPuyo = {
  RequirementColor.Garbage: Cell.Garbage.Puyo,
  RequirementColor.Red: Cell.Red.Puyo,
  RequirementColor.Green: Cell.Green.Puyo,
  RequirementColor.Blue: Cell.Blue.Puyo,
  RequirementColor.Yellow: Cell.Yellow.Puyo,
  RequirementColor.Purple: Cell.Purple.Puyo}.toTable

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
  ## In `solvedBody`, `Accept` should be returned if the requirement is
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

# ------------------------------------------------
# Requirement-specific
# ------------------------------------------------

func markClear[F: TsuField or WaterField](
    nazo: NazoPuyo[F], positions: Positions): MarkResult
    {.inline.} =
  ## Marks the positions with `Clear` requirement.
  nazo.markTmpl(positions, environment.move[F], true):
    discard moveResult # HACK: remove warning
    return Accept

func markDisappearColor[F: TsuField or WaterField](
    nazo: NazoPuyo[F], positions: Positions,
    kind: static RequirementKind): MarkResult {.inline.} =
  ## Marks the positions with `DisappearColor[More]` requirement.
  var colors = set[ColorPuyo]({})

  nazo.markTmpl(positions, environment.moveWithRoughTracking[F], false):
    colors.incl moveResult.colors

    if colors.disappearColorSatisfied(nazo.requirement, kind):
      return Accept

func markDisappearCount[F: TsuField or WaterField](
    nazo: NazoPuyo[F], positions: Positions,
    kind: static RequirementKind): MarkResult {.inline.} =
  ## Marks the positions with `DisappearCount[More]` requirement.
  var count = 0

  nazo.markTmpl(positions, environment.moveWithRoughTracking[F], false):
    count.inc case nazo.requirement.color.get
    of RequirementColor.All: moveResult.puyoCount
    of RequirementColor.Color: moveResult.colorCount
    else: moveResult.puyoCount ReqColorToPuyo[nazo.requirement.color.get]

    if count.disappearCountSatisfied(nazo.requirement, kind):
      return Accept

func markChain[F: TsuField or WaterField](
    nazo: NazoPuyo[F], positions: Positions,
    kind: static RequirementKind): MarkResult {.inline.} =
  ## Marks the positions with `Chain[More]` requirement.
  nazo.markTmpl(positions, environment.move[F], false):
    if moveResult.chainSatisfied(nazo.requirement, kind):
      return Accept

func markChainClear[F: TsuField or WaterField](
    nazo: NazoPuyo[F], positions: Positions,
    kind: static RequirementKind): MarkResult {.inline.} =
  ## Marks the positions with `Chain[More]Clear` requirement.
  nazo.markTmpl(positions, environment.move[F], true):
    if moveResult.chainSatisfied(nazo.requirement, kind):
      return Accept

func markDisappearColorSametime[F: TsuField or WaterField](
    nazo: NazoPuyo[F], positions: Positions,
    kind: static RequirementKind): MarkResult {.inline.} =
  ## Marks the positions with `DisappearColor[More]Sametime` requirement.
  nazo.markTmpl(positions, environment.moveWithDetailTracking[F], false):
    if moveResult.disappearColorSametimeSatisfied(nazo.requirement, kind):
      return Accept

func markDisappearCountSametime[F: TsuField or WaterField](
    nazo: NazoPuyo[F], positions: Positions,
    kind: static RequirementKind): MarkResult {.inline.} =
  ## Marks the positions with `DisappearCount[More]Sametime` requirement.
  nazo.markTmpl(positions, environment.moveWithDetailTracking[F], false):
    if moveResult.disappearCountSametimeSatisfied(nazo.requirement, kind):
      return Accept

func markDisappearPlace[F: TsuField or WaterField](
    nazo: NazoPuyo[F], positions: Positions,
    kind: static RequirementKind): MarkResult {.inline.} =
  ## Marks the positions with `DisappearPlace[More]Sametime` requirement.
  nazo.markTmpl(positions, environment.moveWithFullTracking[F], false):
    if moveResult.disappearPlaceSatisfied(nazo.requirement, kind):
      return Accept

func markDisappearConnect[F: TsuField or WaterField](
    nazo: NazoPuyo[F], positions: Positions,
    kind: static RequirementKind): MarkResult {.inline.} =
  ## Marks the positions with `DisappearConnect[More]Sametime` requirement.
  nazo.markTmpl(positions, environment.moveWithFullTracking[F], false):
    if moveResult.disappearConnectSatisfied(nazo.requirement, kind):
      return Accept

# ------------------------------------------------
# Mark
# ------------------------------------------------

func mark*[F: TsuField or WaterField](nazo: NazoPuyo[F], positions: Positions):
    MarkResult {.inline.} =
  ## Marks the positions.
  if not nazo.requirement.isSupported:
    return NotSupport

  result = case nazo.requirement.kind
  of Clear: nazo.markClear positions
  of DisappearColor: nazo.markDisappearColor(positions, DisappearColor)
  of DisappearColorMore: nazo.markDisappearColor(positions, DisappearColorMore)
  of DisappearCount: nazo.markDisappearCount(positions, DisappearCount)
  of DisappearCountMore: nazo.markDisappearCount(positions, DisappearCountMore)
  of Chain: nazo.markChain(positions, Chain)
  of ChainMore: nazo.markChain(positions, ChainMore)
  of ChainClear: nazo.markChainClear(positions, ChainClear)
  of ChainMoreClear: nazo.markChainClear(positions, ChainMoreClear)
  of DisappearColorSametime:
    nazo.markDisappearColorSametime(positions, DisappearColorSametime)
  of DisappearColorMoreSametime:
    nazo.markDisappearColorSametime(positions, DisappearColorMoreSametime)
  of DisappearCountSametime:
    nazo.markDisappearCountSametime(positions, DisappearCountSametime)
  of DisappearCountMoreSametime:
    nazo.markDisappearCountSametime(positions, DisappearCountMoreSametime)
  of DisappearPlace: nazo.markDisappearPlace(positions, DisappearPlace)
  of DisappearPlaceMore: nazo.markDisappearPlace(positions, DisappearPlaceMore)
  of DisappearConnect: nazo.markDisappearConnect(positions, DisappearConnect)
  of DisappearConnectMore:
    nazo.markDisappearConnect(positions, DisappearConnectMore)
