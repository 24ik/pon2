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
      positions: Positions, nazo: NazoPuyo[F], needClear: static bool,
      moveFn: M, solvedBody: untyped): untyped =
  ## Marking framework.
  ##
  ## Requirement-specific process should be implemented in `solvedBody`
  ## just like:
  ## ```
  ## if <requirement is satisfied>:
  ##   return Accept
  ## ```
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
    when needClear:
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
    positions: Positions, nazo: NazoPuyo[F]): MarkResult {.inline.} =
  ## Marks the positions with `Clear` requirement.
  positions.markTmpl(nazo, true, environment.move[F]):
    discard moveResult # HACK: remove warning
    return Accept

func markDisappearColor[F: TsuField or WaterField](
    positions: Positions, nazo: NazoPuyo[F],
    kind: static RequirementKind): MarkResult {.inline.} =
  ## Marks the positions with `DisappearColor[More]` requirement.
  var colors = set[ColorPuyo]({})

  positions.markTmpl(nazo, false, environment.moveWithRoughTracking[F]):
    colors.incl moveResult.colors

    if colors.disappearColorSatisfied(nazo.requirement, kind):
      return Accept

func markDisappearCount[F: TsuField or WaterField](
    positions: Positions, nazo: NazoPuyo[F],
    kind: static RequirementKind): MarkResult {.inline.} =
  ## Marks the positions with `DisappearCount[More]` requirement.
  var count = 0

  positions.markTmpl(nazo, false, environment.moveWithRoughTracking[F]):
    count.inc case nazo.requirement.color.get
    of RequirementColor.All: moveResult.puyoCount
    of RequirementColor.Color: moveResult.colorCount
    else: moveResult.puyoCount ReqColorToPuyo[nazo.requirement.color.get]

    if count.disappearCountSatisfied(nazo.requirement, kind):
      return Accept

func markChain[F: TsuField or WaterField](
    positions: Positions, nazo: NazoPuyo[F],
    kind: static RequirementKind): MarkResult {.inline.} =
  ## Marks the positions with `Chain[More]` requirement.
  positions.markTmpl(nazo, false, environment.move[F]):
    if moveResult.chainSatisfied(nazo.requirement, kind):
      return Accept

func markChainClear[F: TsuField or WaterField](
    positions: Positions, nazo: NazoPuyo[F],
    kind: static RequirementKind): MarkResult {.inline.} =
  ## Marks the positions with `Chain[More]Clear` requirement.
  positions.markTmpl(nazo, true, environment.move[F]):
    if moveResult.chainSatisfied(nazo.requirement, kind):
      return Accept

func markDisappearColorSametime[F: TsuField or WaterField](
    positions: Positions, nazo: NazoPuyo[F],
    kind: static RequirementKind): MarkResult {.inline.} =
  ## Marks the positions with `DisappearColor[More]Sametime` requirement.
  positions.markTmpl(nazo, false, environment.moveWithDetailTracking[F]):
    if moveResult.disappearColorSametimeSatisfied(nazo.requirement, kind):
      return Accept

func markDisappearCountSametime[F: TsuField or WaterField](
    positions: Positions, nazo: NazoPuyo[F],
    kind: static RequirementKind): MarkResult {.inline.} =
  ## Marks the positions with `DisappearCount[More]Sametime` requirement.
  positions.markTmpl(nazo, false, environment.moveWithDetailTracking[F]):
    if moveResult.disappearCountSametimeSatisfied(nazo.requirement, kind):
      return Accept

func markDisappearPlace[F: TsuField or WaterField](
    positions: Positions, nazo: NazoPuyo[F],
    kind: static RequirementKind): MarkResult {.inline.} =
  ## Marks the positions with `DisappearPlace[More]Sametime` requirement.
  positions.markTmpl(nazo, false, environment.moveWithFullTracking[F]):
    if moveResult.disappearPlaceSatisfied(nazo.requirement, kind):
      return Accept

func markDisappearConnect[F: TsuField or WaterField](
    positions: Positions, nazo: NazoPuyo[F],
    kind: static RequirementKind): MarkResult {.inline.} =
  ## Marks the positions with `DisappearConnect[More]Sametime` requirement.
  positions.markTmpl(nazo, false, environment.moveWithFullTracking[F]):
    if moveResult.disappearConnectSatisfied(nazo.requirement, kind):
      return Accept

# ------------------------------------------------
# Mark
# ------------------------------------------------

func mark*[F: TsuField or WaterField](
    positions: Positions, nazo: NazoPuyo[F]): MarkResult {.inline.} =
  ## Marks the positions.
  if not nazo.requirement.isSupported:
    return NotSupport

  result = case nazo.requirement.kind
  of Clear: positions.markClear nazo
  of DisappearColor: positions.markDisappearColor(nazo, DisappearColor)
  of DisappearColorMore: positions.markDisappearColor(nazo, DisappearColorMore)
  of DisappearCount: positions.markDisappearCount(nazo, DisappearCount)
  of DisappearCountMore: positions.markDisappearCount(nazo, DisappearCountMore)
  of Chain: positions.markChain(nazo, Chain)
  of ChainMore: positions.markChain(nazo, ChainMore)
  of ChainClear: positions.markChainClear(nazo, ChainClear)
  of ChainMoreClear: positions.markChainClear(nazo, ChainMoreClear)
  of DisappearColorSametime:
    positions.markDisappearColorSametime(nazo, DisappearColorSametime)
  of DisappearColorMoreSametime:
    positions.markDisappearColorSametime(nazo, DisappearColorMoreSametime)
  of DisappearCountSametime:
    positions.markDisappearCountSametime(nazo, DisappearCountSametime)
  of DisappearCountMoreSametime:
    positions.markDisappearCountSametime(nazo, DisappearCountMoreSametime)
  of DisappearPlace: positions.markDisappearPlace(nazo, DisappearPlace)
  of DisappearPlaceMore: positions.markDisappearPlace(nazo, DisappearPlaceMore)
  of DisappearConnect: positions.markDisappearConnect(nazo, DisappearConnect)
  of DisappearConnectMore:
    positions.markDisappearConnect(nazo, DisappearConnectMore)
