## This module implements Nazo Puyo.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, uri]
import
  ./[cell, field, fqdn, goal, moveresult, pair, placement, popresult, puyopuyo, step]
import ../private/[assign, bitutils, core, results2, strutils, tables]

export goal, puyopuyo, results2

type
  NazoPuyo* = object ## Nazo Puyo.
    puyoPuyo*: PuyoPuyo
    goal*: Goal

  MarkResult* {.pure.} = enum
    ## Marking result.
    Accept = "クリア！"
    WrongAnswer = ""
    Dead = "ばたんきゅ〜"
    InvalidMove = "不可能な設置"
    SkipMove = "設置スキップ"
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

const
  DummyCell = Cell.low
  GoalColorToCell: array[GoalColor, Cell] = [
    DummyCell, Cell.Red, Cell.Green, Cell.Blue, Cell.Yellow, Cell.Purple, DummyCell,
    DummyCell,
  ]

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
    of PairPlacement:
      if step.optPlacement.isOk:
        if skipped:
          return SkipMove
        if step.optPlacement.unsafeValue in puyoPuyo.field.invalidPlacements:
          return InvalidMove
      else:
        skipped = true
    of StepKind.Garbages, Rotate:
      discard

    let moveResult = puyoPuyo.move calcConnection

    # update accumulative results
    if self.goal.mainOpt.isOk:
      let main = self.goal.mainOpt.unsafeValue

      case main.kind
      of AccumColor:
        popColors.incl moveResult.colors
      of AccumCount:
        let addCount =
          case main.color
          of All:
            moveResult.puyoCount
          of GoalColor.Garbages:
            moveResult.garbagesCount
          of Colors:
            moveResult.colorPuyoCount
          else:
            moveResult.cellCount GoalColorToCell[main.color]

        popCount.inc addCount
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
            of GoalColor.Garbages:
              puyoPuyo.field.garbagesCount
            of Colors:
              puyoPuyo.field.colorPuyoCount
            else:
              puyoPuyo.field.cellCount GoalColorToCell[clearColor]

        count == 0
      else:
        true

    # check kind-specific
    if clearSatisfied:
      let kindSatisfied =
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

      if kindSatisfied:
        return Accept

    # check dead
    if puyoPuyo.field.isDead:
      return Dead

  WrongAnswer

# ------------------------------------------------
# Nazo Puyo <-> string
# ------------------------------------------------

const GoalPuyoPuyoSep = "\n======\n"

func `$`*(self: NazoPuyo): string {.inline, noinit.} =
  $self.goal & GoalPuyoPuyoSep & $self.puyoPuyo

func parseNazoPuyo*(str: string): StrErrorResult[NazoPuyo] {.inline, noinit.} =
  ## Returns the Nazo Puyo converted from the string representation.
  let
    errorMsg = "Invalid Nazo Puyo: {str}".fmt
    strs = str.split GoalPuyoPuyoSep
  if strs.len != 2:
    return err "Invalid Nazo Puyo: {str}".fmt

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

func toUriQueryPon2(self: NazoPuyo): StrErrorResult[string] {.inline, noinit.} =
  ## Returns the URI query converted from the Nazo Puyo.
  let errorMsg = "Nazo Puyo that does not support URI conversion: {self}".fmt

  ok (?self.puyoPuyo.toUriQuery(Pon2).context errorMsg) & '&' &
    [(GoalKey, ?self.goal.toUriQuery(Pon2).context errorMsg)].encodeQuery

func toUriQueryIshikawa(self: NazoPuyo): StrErrorResult[string] {.inline, noinit.} =
  ## Returns the URI query converted from the Nazo Puyo.
  let
    errorMsg = "Nazo Puyo that does not support URI conversion: {self}".fmt
    puyoPuyoQueryRaw = ?self.puyoPuyo.toUriQuery(Ishikawa).context errorMsg
    puyoPuyoQuery =
      if '_' in puyoPuyoQueryRaw:
        puyoPuyoQueryRaw
      else:
        puyoPuyoQueryRaw & '_'
  ok puyoPuyoQuery & IshikawaPuyoPuyoGoalSep &
    ?self.goal.toUriQuery(Ishikawa).context errorMsg

func toUriQuery*(
    self: NazoPuyo, fqdn = Pon2
): StrErrorResult[string] {.inline, noinit.} =
  ## Returns the URI query converted from the Nazo Puyo.
  case fqdn
  of Pon2: self.toUriQueryPon2
  of Ishikawa, Ips: self.toUriQueryIshikawa

func parseNazoPuyoPon2(query: string): StrErrorResult[NazoPuyo] {.inline, noinit.} =
  ## Returns the Nazo Puyo converted from the URI query.
  var
    nazoPuyo = NazoPuyo.init
    goalSet = false
    keyVals = newSeq[(string, string)](0)

  for (key, val) in query.decodeQuery:
    case key
    of GoalKey:
      if goalSet:
        return err "Invalid Nazo Puyo (multiple `key`): {query}".fmt
      goalSet.assign true

      nazoPuyo.goal.assign ?val.parseGoal(Pon2).context "Invalid Nazo Puyo: {query}".fmt
    else:
      keyVals.add (key, val)

  if not goalSet:
    nazoPuyo.goal.assign ?"".parseGoal(Pon2).context "Unexpected error (parseNazoPuyoPon2)"

  nazoPuyo.puyoPuyo.assign ?parsePuyoPuyo(keyVals.encodeQuery, Pon2).context "Invalid Nazo Puyo: {query}".fmt

  ok nazoPuyo

func parseNazoPuyoIshikawa(query: string): StrErrorResult[NazoPuyo] {.inline, noinit.} =
  ## Returns the Nazo Puyo converted from the URI query.
  let
    errorMsg = "Invalid Nazo Puyo: {query}".fmt
    strs = query.rsplit(IshikawaPuyoPuyoGoalSep, 1)
  if strs.len notin 1 .. 2:
    return err errorMsg

  ok NazoPuyo.init(
    ?strs[0].parsePuyoPuyo(Ishikawa).context errorMsg,
    if strs.len == 1:
      NoneGoal
    else:
      ?strs[1].parseGoal(Ishikawa).context errorMsg,
  )

func parseNazoPuyo*(
    query: string, fqdn: SimulatorFqdn
): StrErrorResult[NazoPuyo] {.inline, noinit.} =
  ## Returns the Nazo Puyo converted from the URI query.
  case fqdn
  of Pon2: query.parseNazoPuyoPon2
  of Ishikawa, Ips: query.parseNazoPuyoIshikawa
