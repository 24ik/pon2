## This module implements Puyo Puyo.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, uri]
import ./[cell, field, fqdn, moveresult, pair, placement, popresult, step]
import ../[utils]
import ../private/[assign, bitutils, strutils, tables]

export field, moveresult, step, utils

type PuyoPuyo* = object ## Puyo Puyo game.
  field*: Field
  steps*: Steps

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type PuyoPuyo, field: Field, steps: Steps): T {.inline, noinit.} =
  T(field: field, steps: steps)

func init*(T: type PuyoPuyo, rule = Rule.Tsu): T {.inline, noinit.} =
  T.init(Field.init rule, Steps.init)

# ------------------------------------------------
# Count
# ------------------------------------------------

func cellCount*(self: PuyoPuyo, cell: Cell): int {.inline, noinit.} =
  ## Returns the number of `cell` in the game.
  self.field.cellCount(cell) + self.steps.cellCount(cell)

func puyoCount*(self: PuyoPuyo): int {.inline, noinit.} =
  ## Returns the number of puyos in the game.
  self.field.puyoCount + self.steps.puyoCount

func colorPuyoCount*(self: PuyoPuyo): int {.inline, noinit.} =
  ## Returns the number of color puyos in the game.
  self.field.colorPuyoCount + self.steps.colorPuyoCount

func garbagesCount*(self: PuyoPuyo): int {.inline, noinit.} =
  ## Returns the number of hard and garbage puyos in the game.
  self.field.garbagesCount + self.steps.garbagesCount

# ------------------------------------------------
# Move
# ------------------------------------------------

func move*(self: var PuyoPuyo, calcConnection = true): MoveResult {.inline, noinit.} =
  ## Applies the step and advances the field until chains end.
  ## This function requires that the field is settled.
  if self.steps.len == 0:
    return MoveResult.init

  self.field.move(self.steps.popFirst, calcConnection)

# ------------------------------------------------
# Puyo Puyo <-> string
# ------------------------------------------------

const FieldStepsSep = "\n------\n"

func `$`*(self: PuyoPuyo): string {.inline, noinit.} =
  $self.field & FieldStepsSep & $self.steps

func parsePuyoPuyo*(str: string): Pon2Result[PuyoPuyo] {.inline, noinit.} =
  ## Returns the game converted from the string representation.
  let strs = str.split FieldStepsSep
  if strs.len != 2:
    return err "Invalid Puyo Puyo: {str}".fmt

  let
    errorMsg = "Invalid Puyo Puyo: {str}".fmt
    field = ?strs[0].parseField.context errorMsg
    steps = ?strs[1].parseSteps.context errorMsg

  ok PuyoPuyo.init(field, steps)

# ------------------------------------------------
# Puyo Puyo <-> URI
# ------------------------------------------------

const
  FieldKey = "field"
  StepsKey = "steps"

  FieldStepsSepIshikawaUri = "_"

func toUriQueryPon2(self: PuyoPuyo): Pon2Result[string] {.inline, noinit.} =
  ## Returns the URI query converted from the game.
  let errorMsg = "Puyo Puyo that does not support URI conversion: {self}".fmt

  ok [
    (FieldKey, ?self.field.toUriQuery(Pon2).context errorMsg),
    (StepsKey, ?self.steps.toUriQuery(Pon2).context errorMsg),
  ].encodeQuery

func toUriQueryIshikawa(self: PuyoPuyo): Pon2Result[string] {.inline, noinit.} =
  ## Returns the URI query converted from the game.
  let
    errorMsg = "Puyo Puyo that does not support URI conversion: {self}".fmt

    fieldQuery = ?self.field.toUriQuery(IshikawaPuyo).context errorMsg
    stepsQuery = ?self.steps.toUriQuery(IshikawaPuyo).context errorMsg

  ok (
    if stepsQuery == "": fieldQuery
    else: fieldQuery & FieldStepsSepIshikawaUri & stepsQuery
  )

func toUriQuery*(self: PuyoPuyo, fqdn = Pon2): Pon2Result[string] {.inline, noinit.} =
  ## Returns the URI query converted from the game.
  case fqdn
  of Pon2: self.toUriQueryPon2
  of IshikawaPuyo, Ips: self.toUriQueryIshikawa

func parsePuyoPuyoPon2(query: string): Pon2Result[PuyoPuyo] {.inline, noinit.} =
  ## Returns the game converted from the URI query.
  var
    puyoPuyo = PuyoPuyo.init
    fieldSet = false
    stepsSet = false

  for (key, val) in query.decodeQuery:
    case key
    of FieldKey:
      if fieldSet:
        return err "Invalid Puyo Puyo (multiple `{key}`): {query}".fmt
      fieldSet.assign true

      # NOTE: assign does not work
      puyoPuyo.field = ?val.parseField(Pon2).context "Invalid Puyo Puyo: {query}".fmt
    of StepsKey:
      if stepsSet:
        return err "Invalid Puyo Puyo (multiple `{key}`): {query}".fmt
      stepsSet.assign true

      puyoPuyo.steps.assign ?val.parseSteps(Pon2).context "Invalid Puyo Puyo: {query}".fmt
    else:
      return err "Invalid Puyo Puyo (Invalid key: `{key}`): {query}".fmt

  if not fieldSet:
    puyoPuyo.field = ?"".parseField(Pon2).context "Unexpected error (parsePuyoPuyoPon2)"
  if not stepsSet:
    puyoPuyo.steps.assign ?"".parseSteps(Pon2).context "Unexpected error (parsePuyoPuyoPon2)"

  ok puyoPuyo

func parsePuyoPuyoIshikawa(query: string): Pon2Result[PuyoPuyo] {.inline, noinit.} =
  ## Returns the game converted from the URI query.
  let strs = query.split FieldStepsSepIshikawaUri

  var steps = Steps.init
  case strs.len
  of 1:
    discard
  of 2:
    steps.assign ?strs[1].parseSteps(IshikawaPuyo).context "Invalid Puyo Puyo: {query}".fmt
  else:
    return err "Invalid Puyo Puyo: {query}".fmt

  let field = ?strs[0].parseField(IshikawaPuyo).context "Invalid Puyo Puyo: {query}".fmt

  ok PuyoPuyo.init(field, steps)

func parsePuyoPuyo*(
    query: string, fqdn: SimulatorFqdn
): Pon2Result[PuyoPuyo] {.inline, noinit.} =
  ## Returns the game converted from the URI query.
  case fqdn
  of Pon2: query.parsePuyoPuyoPon2
  of IshikawaPuyo, Ips: query.parsePuyoPuyoIshikawa
