## This module implements Puyo Puyo.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, typetraits, uri]
import ./[cell, field, fqdn, moveresult, pair, placement, popresult, step]
import ../private/[assign, bitutils, macros, strutils, tables]

export field, moveresult, results2, step

type PuyoPuyo*[F: TsuField or WaterField] = object ## Puyo Puyo game.
  field*: F
  steps*: Steps

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*[F: TsuField or WaterField](
    T: type PuyoPuyo[F], field: F, steps: Steps
): T {.inline, noinit.} =
  T(field: field, steps: steps)

func init*[F: TsuField or WaterField](T: type PuyoPuyo[F]): T {.inline, noinit.} =
  T.init(F.init, Steps.init)

# ------------------------------------------------
# Count
# ------------------------------------------------

func cellCount*[F: TsuField or WaterField](
    self: PuyoPuyo[F], cell: Cell
): int {.inline, noinit.} =
  ## Returns the number of `cell` in the game.
  self.field.cellCount(cell) + self.steps.cellCount(cell)

func puyoCount*[F: TsuField or WaterField](self: PuyoPuyo[F]): int {.inline, noinit.} =
  ## Returns the number of puyos in the game.
  self.field.puyoCount + self.steps.puyoCount

func colorPuyoCount*[F: TsuField or WaterField](
    self: PuyoPuyo[F]
): int {.inline, noinit.} =
  ## Returns the number of color puyos in the game.
  self.field.colorPuyoCount + self.steps.colorPuyoCount

func garbagesCount*[F: TsuField or WaterField](
    self: PuyoPuyo[F]
): int {.inline, noinit.} =
  ## Returns the number of hard and garbage puyos in the game.
  self.field.garbagesCount + self.steps.garbagesCount

# ------------------------------------------------
# Move
# ------------------------------------------------

func move*[F: TsuField or WaterField](
    self: var PuyoPuyo[F], calcConn = true
): MoveResult {.inline, noinit.} =
  ## Applies the step and advances the field until chains end.
  ## This function requires that the field is settled.
  if self.steps.len == 0:
    return MoveResult.init

  self.field.move(self.steps.popFirst, calcConn)

# ------------------------------------------------
# Puyo Puyo <-> string
# ------------------------------------------------

const FieldStepsSep = "\n------\n"

func `$`*[F: TsuField or WaterField](self: PuyoPuyo[F]): string {.inline, noinit.} =
  $self.field & FieldStepsSep & $self.steps

func parsePuyoPuyo*[F: TsuField or WaterField](
    str: string
): StrErrorResult[PuyoPuyo[F]] {.inline, noinit.} =
  ## Returns the game converted from the string representation.
  let strs = str.split FieldStepsSep
  if strs.len != 2:
    return err "Invalid Puyo Puyo: {str}".fmt

  let
    errorMsg = "Invalid Puyo Puyo: {str}".fmt
    field =
      when F is TsuField:
        ?strs[0].parseTsuField.context errorMsg
      else:
        ?strs[0].parseWaterField.context errorMsg
    steps = ?strs[1].parseSteps.context errorMsg

  ok PuyoPuyo[F].init(field, steps)

# ------------------------------------------------
# Puyo Puyo <-> URI
# ------------------------------------------------

const
  FieldKey = "field"
  StepsKey = "steps"

  FieldStepsSepIshikawaUri = "_"

func toUriQueryPon2[F: TsuField or WaterField](
    self: PuyoPuyo[F]
): StrErrorResult[string] {.inline, noinit.} =
  ## Returns the URI query converted from the game.
  let errorMsg = "Puyo Puyo that does not support URI conversion: {self}".fmt

  ok [
    (FieldKey, ?self.field.toUriQuery(Pon2).context errorMsg),
    (StepsKey, ?self.steps.toUriQuery(Pon2).context errorMsg),
  ].encodeQuery

func toUriQueryIshikawa[F: TsuField or WaterField](
    self: PuyoPuyo[F]
): StrErrorResult[string] {.inline, noinit.} =
  ## Returns the URI query converted from the game.
  let
    errorMsg = "Puyo Puyo that does not support URI conversion: {self}".fmt

    fieldQuery = ?self.field.toUriQuery(Ishikawa).context errorMsg
    stepsQuery = ?self.steps.toUriQuery(Ishikawa).context errorMsg

  ok (
    if stepsQuery == "": fieldQuery
    else: fieldQuery & FieldStepsSepIshikawaUri & stepsQuery
  )

func toUriQuery*[F: TsuField or WaterField](
    self: PuyoPuyo[F], fqdn = Pon2
): StrErrorResult[string] {.inline, noinit.} =
  ## Returns the URI query converted from the game.
  case fqdn
  of Pon2: self.toUriQueryPon2
  of Ishikawa, Ips: self.toUriQueryIshikawa

func parsePuyoPuyoPon2[F: TsuField or WaterField](
    query: string
): StrErrorResult[PuyoPuyo[F]] {.inline, noinit.} =
  ## Returns the game converted from the URI query.
  var
    puyoPuyo = PuyoPuyo[F].init
    fieldSet = false
    stepsSet = false

  for (key, val) in query.decodeQuery:
    case key
    of FieldKey:
      if fieldSet:
        return err "Invalid Puyo Puyo (multiple `{key}`): {query}".fmt
      fieldSet.assign true

      # NOTE: somehow `assign` does not compile
      puyoPuyo.field = (
        when F is TsuField:
          ?val.parseTsuField(Pon2).context "Invalid Puyo Puyo: {query}".fmt
        else:
          ?val.parseWaterField(Pon2).context "Invalid Puyo Puyo: {query}".fmt
      )
    of StepsKey:
      if stepsSet:
        return err "Invalid Puyo Puyo (multiple `{key}`): {query}".fmt
      stepsSet.assign true

      puyoPuyo.steps.assign ?val.parseSteps(Pon2).context "Invalid Puyo Puyo: {query}".fmt
    else:
      return err "Invalid Puyo Puyo (Invalid key: `{key}`): {query}".fmt

  if not fieldSet:
    when F is TsuField:
      # NOTE: somehow `assign` does not compile
      puyoPuyo.field =
        ?"".parseTsuField(Pon2).context "Unexpected error (parsePuyoPuyoPon2)"
    else:
      return err "Invalid Puyo Puyo (missing key `field`)"
  if not stepsSet:
    puyoPuyo.steps.assign ?"".parseSteps(Pon2).context "Unexpected error (parsePuyoPuyoPon2)"

  ok puyoPuyo

func parsePuyoPuyoIshikawa[F: TsuField or WaterField](
    query: string
): StrErrorResult[PuyoPuyo[F]] {.inline, noinit.} =
  ## Returns the game converted from the URI query.
  let strs = query.split FieldStepsSepIshikawaUri

  var steps = Steps.init
  case strs.len
  of 1:
    discard
  of 2:
    steps.assign ?strs[1].parseSteps(Ishikawa).context "Invalid Puyo Puyo: {query}".fmt
  else:
    return err "Invalid Puyo Puyo: {query}".fmt

  let field =
    when F is TsuField:
      ?strs[0].parseTsuField(Ishikawa).context "Invalid Puyo Puyo: {query}".fmt
    else:
      ?strs[0].parseWaterField(Ishikawa).context "Invalid Puyo Puyo: {query}".fmt

  ok PuyoPuyo[F].init(field, steps)

func parsePuyoPuyo*[F: TsuField or WaterField](
    query: string, fqdn: SimulatorFqdn
): StrErrorResult[PuyoPuyo[F]] {.inline, noinit.} =
  ## Returns the game converted from the URI query.
  case fqdn
  of Pon2:
    parsePuyoPuyoPon2[F](query)
  of Ishikawa, Ips:
    parsePuyoPuyoIshikawa[F](query)
