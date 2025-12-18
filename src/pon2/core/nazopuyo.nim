## This module implements Nazo Puyo.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, uri]
import
  ./[cell, field, fqdn, goal, moveresult, pair, placement, popresult, puyopuyo, step]
import ../[utils]
import ../private/[assign, bitops, core, strutils, tables]

export goal, puyopuyo, utils

type
  NazoPuyo* = object ## Nazo Puyo.
    puyoPuyo*: PuyoPuyo
    goal*: Goal

  MarkResult* {.pure.} = enum
    ## Nazo Puyo marking result.
    Correct = "クリア！"
    Incorrect = ""
    Dead = "ばたんきゅ〜"
    InvalidPlace = "不可能な設置"
    PlaceSkip = "設置スキップ"
    NotSupport = "未対応の条件"

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type NazoPuyo, puyoPuyo: PuyoPuyo, goal: Goal): T {.inline, noinit.} =
  T(puyoPuyo: puyoPuyo, goal: goal)

func init*(T: type NazoPuyo, rule = Rule.Tsu): T {.inline, noinit.} =
  T.init(PuyoPuyo.init rule, Goal.init)

# ------------------------------------------------
# Mark
# ------------------------------------------------

func mark*(self: NazoPuyo, endStepIndex = -1): MarkResult {.inline, noinit.} =
  ## Marks the steps in the Nazo Puyo.
  ## If `endStepIndex` is negative, all steps are used.
  ## This function requires that the field is settled.
  if not self.goal.isSupported:
    return NotSupport

  let
    calcConnection =
      self.goal.mainOpt.isOk and
      self.goal.mainOpt.unsafeValue.kind in {Place, Connection}
    loopCount =
      if endStepIndex in 0 .. self.puyoPuyo.steps.len:
        endStepIndex
      else:
        self.puyoPuyo.steps.len
  var
    puyoPuyo = self.puyoPuyo
    skipped = false
    popColors = set[Cell]({}) # used by AccumColor
    popCount = 0 # used by AccumCount

  for _ in 1 .. loopCount:
    let step = puyoPuyo.steps.peekFirst

    # check skip, invalid
    case step.kind
    of PairPlace:
      case step.placement
      of Placement.None:
        skipped.assign true
      else:
        if skipped:
          return PlaceSkip
        if step.placement in puyoPuyo.field.invalidPlacements:
          return InvalidPlace
    of NuisanceDrop, FieldRotate:
      discard

    let moveResult = puyoPuyo.move calcConnection

    # update accumulative results
    if self.goal.mainOpt.isOk:
      let main = self.goal.mainOpt.unsafeValue

      case main.kind
      of AccumColor:
        popColors.incl moveResult.colors
      of AccumCount:
        popCount += (
          case main.color
          of All:
            moveResult.puyoCount
          of Nuisance:
            moveResult.nuisancePuyoCount
          of Colored:
            moveResult.coloredPuyoCount
          else:
            moveResult.cellCount main.color.ord.Cell
        )
      else:
        discard

    # check clear
    let clearSatisfied =
      if self.goal.clearColorOpt.isOk:
        let
          clearColor = self.goal.clearColorOpt.unsafeValue
          count =
            case clearColor
            of All:
              puyoPuyo.field.puyoCount
            of Nuisance:
              puyoPuyo.field.nuisancePuyoCount
            of Colored:
              puyoPuyo.field.coloredPuyoCount
            else:
              puyoPuyo.field.cellCount clearColor.ord.Cell

        count == 0
      else:
        true

    # check kind-specific
    let satisfied =
      clearSatisfied and (
        if self.goal.mainOpt.isOk:
          case self.goal.mainOpt.unsafeValue.kind
          of Chain:
            self.goal.isSatisfiedChain moveResult
          of Color:
            self.goal.isSatisfiedColor moveResult
          of Count:
            self.goal.isSatisfiedCount moveResult
          of Place:
            self.goal.isSatisfiedPlace moveResult
          of Connection:
            self.goal.isSatisfiedConnection moveResult
          of AccumColor:
            self.goal.isSatisfiedAccumColor popColors
          of AccumCount:
            self.goal.isSatisfiedAccumCount popCount
        else:
          true
      )

    if satisfied:
      return Correct
    if puyoPuyo.field.isDead:
      return Dead

  Incorrect

# ------------------------------------------------
# Nazo Puyo <-> string
# ------------------------------------------------

const GoalPuyoPuyoSep = "\n======\n"

func `$`*(self: NazoPuyo): string {.inline, noinit.} =
  $self.goal & GoalPuyoPuyoSep & $self.puyoPuyo

func parseNazoPuyo*(str: string): Pon2Result[NazoPuyo] {.inline, noinit.} =
  ## Returns the Nazo Puyo converted from the string representation.
  let errorMsg = "Invalid Nazo Puyo: {str}".fmt

  let strs = str.split GoalPuyoPuyoSep
  if strs.len != 2:
    return err errorMsg

  let
    goal = ?strs[0].parseGoal.context errorMsg
    puyoPuyo = ?strs[1].parsePuyoPuyo.context errorMsg

  ok NazoPuyo.init(puyoPuyo, goal)

# ------------------------------------------------
# Nazo Puyo <-> URI
# ------------------------------------------------

const
  GoalKey = "goal"
  IshikawaPuyoPuyoGoalSep = "__"

func toUriQueryPon2(self: NazoPuyo): Pon2Result[string] {.inline, noinit.} =
  ## Returns the URI query with Pon2 format converted from the Nazo Puyo.
  let errorMsg = "Nazo Puyo that does not support URI conversion: {self}".fmt

  ok (?self.puyoPuyo.toUriQuery(Pon2).context errorMsg) & '&' &
    [(GoalKey, ?self.goal.toUriQuery(Pon2).context errorMsg)].encodeQuery

func toUriQueryIshikawa(self: NazoPuyo): Pon2Result[string] {.inline, noinit.} =
  ## Returns the URI query with IshikawaPuyo/Ips format converted from the Nazo Puyo.
  let
    errorMsg = "Nazo Puyo that does not support URI conversion: {self}".fmt
    puyoPuyoQueryRaw = ?self.puyoPuyo.toUriQuery(IshikawaPuyo).context errorMsg
    puyoPuyoQuery =
      if '_' in puyoPuyoQueryRaw:
        puyoPuyoQueryRaw
      else:
        puyoPuyoQueryRaw & '_'
  ok puyoPuyoQuery & IshikawaPuyoPuyoGoalSep &
    ?self.goal.toUriQuery(IshikawaPuyo).context errorMsg

func toUriQuery*(self: NazoPuyo, fqdn = Pon2): Pon2Result[string] {.inline, noinit.} =
  ## Returns the URI query converted from the Nazo Puyo.
  case fqdn
  of Pon2: self.toUriQueryPon2
  of IshikawaPuyo, Ips: self.toUriQueryIshikawa

func parseNazoPuyoPon2(query: string): Pon2Result[NazoPuyo] {.inline, noinit.} =
  ## Returns the Nazo Puyo converted from the URI query.
  var
    nazoPuyo = NazoPuyo.init
    goalSet = false
    keyVals = newSeq[(string, string)](0)

  for (key, val) in query.decodeQuery:
    case key
    of GoalKey:
      if goalSet:
        return err "Invalid Nazo Puyo (multiple `{key}`): {query}".fmt
      goalSet.assign true

      nazoPuyo.goal.assign ?val.parseGoal(Pon2).context "Invalid Nazo Puyo: {query}".fmt
    else:
      keyVals.add (key, val)

  nazoPuyo.puyoPuyo.assign ?keyVals.encodeQuery.parsePuyoPuyo(Pon2).context "Invalid Nazo Puyo: {query}".fmt

  ok nazoPuyo

func parseNazoPuyoIshikawa(query: string): Pon2Result[NazoPuyo] {.inline, noinit.} =
  ## Returns the Nazo Puyo converted from the URI query.
  let errorMsg = "Invalid Nazo Puyo: {query}".fmt

  let strs = query.rsplit(IshikawaPuyoPuyoGoalSep, 1)
  if strs.len notin 1 .. 2:
    return err errorMsg

  var nazoPuyo = NazoPuyo.init
  nazoPuyo.puyoPuyo.assign ?strs[0].parsePuyoPuyo(IshikawaPuyo).context errorMsg

  if strs.len > 1:
    nazoPuyo.goal.assign ?strs[1].parseGoal(IshikawaPuyo).context errorMsg

  ok nazoPuyo

func parseNazoPuyo*(
    query: string, fqdn: SimulatorFqdn
): Pon2Result[NazoPuyo] {.inline, noinit.} =
  ## Returns the Nazo Puyo converted from the URI query.
  case fqdn
  of Pon2: query.parseNazoPuyoPon2
  of IshikawaPuyo, Ips: query.parseNazoPuyoIshikawa
