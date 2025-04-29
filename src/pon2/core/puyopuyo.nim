## This module implements Puyo Puyo game.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, typetraits, uri]
import ./[cell, field, fqdn, moveresult, pair, placement, popresult, step]
import ../private/[arrayops2, bitops3, macros2, results2, strutils2, tables2]

type PuyoPuyo*[F: TsuField or WaterField] = object ## Puyo Puyo game.
  field*: F
  steps*: Steps

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*[F: TsuField or WaterField](T: type PuyoPuyo[F]): T {.inline.} =
  T(field: F.init, steps: Steps.init)

func init*[F: TsuField or WaterField](
    T: type PuyoPuyo[F], field: F, steps: Steps
): T {.inline.} =
  T(field: field, steps: steps)

# ------------------------------------------------
# Count
# ------------------------------------------------

func cellCnt*[F: TsuField or WaterField](
    self: PuyoPuyo[F], cell: Cell
): int {.inline.} =
  ## Returns the number of `cell` in the game.
  self.field.cellCnt(cell) + self.steps.cellCnt(cell)

func puyoCnt*[F: TsuField or WaterField](self: PuyoPuyo[F]): int {.inline.} =
  ## Returns the number of puyos in the game.
  self.field.puyoCnt + self.steps.puyoCnt

func colorPuyoCnt*[F: TsuField or WaterField](self: PuyoPuyo[F]): int {.inline.} =
  ## Returns the number of color puyos in the game.
  self.field.colorPuyoCnt + self.steps.colorPuyoCnt

func garbagesCnt*[F: TsuField or WaterField](self: PuyoPuyo[F]): int {.inline.} =
  ## Returns the number of hard and garbage puyos in the game.
  self.field.garbagesCnt + self.steps.garbagesCnt

# ------------------------------------------------
# Move
# ------------------------------------------------

func move*[F: TsuField or WaterField](
    self: var PuyoPuyo[F], calcConn: static bool
): MoveResult {.inline.} =
  ## Applies the step and advances the field until chains end.
  ## This function requires that the field is settled.
  if self.steps.len == 0:
    return MoveResult.init(0, initArrWith[Cell, int](0), 0, @[], @[])

  self.field.move(self.steps.popFirst, calcConn)

# ------------------------------------------------
# Puyo Puyo <-> string
# ------------------------------------------------

const FieldStepsSep = "\n------\n"

func `$`*[F: TsuField or WaterField](self: PuyoPuyo[F]): string {.inline.} =
  $self.field & FieldStepsSep & $self.steps

func parsePuyoPuyo*[F: TsuField or WaterField](
    str: string
): Res[PuyoPuyo[F]] {.inline.} =
  ## Returns the game converted from the string representation.
  let strs = str.split FieldStepsSep
  if strs.len != 2:
    return err "Invalid Puyo Puyo: {str}".fmt

  let
    errMsg = "Invalid Puyo Puyo: {str}".fmt
    field =
      when F is TsuField:
        ?strs[0].parseTsuField.context errMsg
      else:
        ?strs[0].parseWaterField.context errMsg
    steps = ?strs[1].parseSteps.context errMsg

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
): Res[string] {.inline.} =
  ## Returns the URI query converted from the game.
  ok [(FieldKey, ?self.field.toUriQuery Pon2), (StepsKey, ?self.steps.toUriQuery Pon2)].encodeQuery

func toUriQueryIshikawa[F: TsuField or WaterField](
    self: PuyoPuyo[F]
): Res[string] {.inline.} =
  ## Returns the URI query converted from the game.
  ok (?self.field.toUriQuery Ishikawa) & FieldStepsSepIshikawaUri &
    ?self.steps.toUriQuery Ishikawa

func toUriQuery*[F: TsuField or WaterField](
    self: PuyoPuyo[F], fqdn = Pon2
): Res[string] {.inline.} =
  ## Returns the URI query converted from the game.
  case fqdn
  of Pon2: self.toUriQueryPon2
  of Ishikawa, Ips: self.toUriQueryIshikawa

func parsePuyoPuyoPon2[F: TsuField or WaterField](
    query: string
): Res[PuyoPuyo[F]] {.inline.} =
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

      fieldSet = true
      puyoPuyo.field =
        when F is TsuField:
          ?val.parseTsuField(Pon2).context "Invalid Puyo Puyo: {query}".fmt
        else:
          ?val.parseWaterField(Pon2).context "Invalid Puyo Puyo: {query}".fmt
    of StepsKey:
      if stepsSet:
        return err "Invalid Puyo Puyo (multiple `{key}`): {query}".fmt

      stepsSet = true
      puyoPuyo.steps = ?val.parseSteps(Pon2).context "Invalid Puyo Puyo: {query}".fmt
    else:
      return err "Invalid Puyo Puyo (Invalid key: `{key}`): {query}".fmt

  if not fieldSet:
    const FieldKey2 = FieldKey # strformat needs this
    return err "Invalid Puyo Puyo (missing `{FieldKey2}`): {query}".fmt
  if not stepsSet:
    const StepsKey2 = StepsKey # strformat needs this
    return err "Invalid Puyo Puyo (missing `{StepsKey2}`): {query}".fmt

  ok puyoPuyo

func parsePuyoPuyoIshikawa[F: TsuField or WaterField](
    query: string
): Res[PuyoPuyo[F]] {.inline.} =
  ## Returns the game converted from the URI query.
  let strs = query.split FieldStepsSepIshikawaUri

  var steps = Steps.init
  case strs.len
  of 1:
    discard
  of 2:
    steps = ?strs[1].parseSteps(Ishikawa).context "Invalid Puyo Puyo: {query}".fmt
  else:
    return err "Invalid Puyo Puyo: {query}".fmt

  let field =
    when F is TsuField:
      ?strs[0].parseTsuField(Ishikawa).context "Invalid Puyo Puyo: {query}".fmt
    else:
      ?strs[0].parseWaterField(Ishikawa).context "Invalid Puyo Puyo: {query}".fmt

  ok PuyoPuyo[F].init(field, steps)

func parsePuyoPuyo*[F: TsuField or WaterField](
    query: string, fqdn: IdeFqdn
): Res[PuyoPuyo[F]] {.inline.} =
  ## Returns the game converted from the URI query.
  case fqdn
  of Pon2:
    parsePuyoPuyoPon2[F](query)
  of Ishikawa, Ips:
    parsePuyoPuyoIshikawa[F](query)
