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

func nuisancePuyoCount*(self: PuyoPuyo): int {.inline, noinit.} =
  ## Returns the number of nuisance puyos in the game.
  self.field.nuisancePuyoCount + self.steps.nuisancePuyoCount

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
  let errorMsg = "Invalid Puyo Puyo: {str}".fmt

  let strs = str.split FieldStepsSep
  if strs.len != 2:
    return err errorMsg

  let
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

func toUriQuery*(self: PuyoPuyo, fqdn = Pon2): Pon2Result[string] {.inline, noinit.} =
  ## Returns the URI query converted from the game.
  let
    errorMsg = "Puyo Puyo that does not support URI conversion: {self}".fmt

    fieldQuery = ?self.field.toUriQuery(fqdn).context errorMsg
    stepsQuery = ?self.steps.toUriQuery(fqdn).context errorMsg

  ok (
    case fqdn
    of Pon2:
      [(FieldKey, fieldQuery), (StepsKey, stepsQuery)].encodeQuery
    of IshikawaPuyo, Ips:
      if stepsQuery == "": fieldQuery
      else:
        fieldQuery & FieldStepsSepIshikawaUri & stepsQuery
  )

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
        return err "Invalid Puyo Puyo (multiple key: `{key}`): {query}".fmt
      fieldSet.assign true

      # NOTE: assign does not work
      puyoPuyo.field = ?val.parseField(Pon2).context "Invalid Puyo Puyo: {query}".fmt
    of StepsKey:
      if stepsSet:
        return err "Invalid Puyo Puyo (multiple key: `{key}`): {query}".fmt
      stepsSet.assign true

      puyoPuyo.steps.assign ?val.parseSteps(Pon2).context "Invalid Puyo Puyo: {query}".fmt
    else:
      return err "Invalid Puyo Puyo (Invalid key: `{key}`): {query}".fmt

  ok puyoPuyo

func parsePuyoPuyoIshikawa(query: string): Pon2Result[PuyoPuyo] {.inline, noinit.} =
  ## Returns the game converted from the URI query.
  let errorMsg = "Invalid Puyo Puyo: {query}".fmt

  let strs = query.split FieldStepsSepIshikawaUri

  var puyoPuyo = PuyoPuyo.init
  puyoPuyo.field =
    ?strs[0].parseField(IshikawaPuyo).context "Invalid Puyo Puyo: {query}".fmt

  case strs.len
  of 1:
    discard
  of 2:
    puyoPuyo.steps.assign ?strs[1].parseSteps(IshikawaPuyo).context errorMsg
  else:
    return err errorMsg

  ok puyoPuyo

func parsePuyoPuyo*(
    query: string, fqdn: SimulatorFqdn
): Pon2Result[PuyoPuyo] {.inline, noinit.} =
  ## Returns the game converted from the URI query.
  case fqdn
  of Pon2: query.parsePuyoPuyoPon2
  of IshikawaPuyo, Ips: query.parsePuyoPuyoIshikawa
