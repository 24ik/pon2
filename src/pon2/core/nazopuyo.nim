## This module implements Nazo Puyo.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, typetraits, uri]
import
  ./[cell, field, fqdn, goal, moveresult, pair, placement, popresult, puyopuyo, step]
import ../private/[assign, bitutils, core, macros, results2, strutils, tables]

export goal, puyopuyo, results2

type
  NazoPuyo*[F: TsuField or WaterField] = object ## Nazo Puyo.
    puyoPuyo*: PuyoPuyo[F]
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

func init*[F: TsuField or WaterField](
    T: type NazoPuyo[F], puyoPuyo: PuyoPuyo[F], goal: Goal
): T {.inline, noinit.} =
  T(puyoPuyo: puyoPuyo, goal: goal)

func init*[F: TsuField or WaterField](T: type NazoPuyo[F]): T {.inline, noinit.} =
  T.init(PuyoPuyo[F].init, Goal.init)

# ------------------------------------------------
# Mark
# ------------------------------------------------

const
  DummyCell = Cell.low
  GoalColorToCell: array[GoalColor, Cell] = [
    DummyCell, Cell.Red, Cell.Green, Cell.Blue, Cell.Yellow, Cell.Purple, DummyCell,
    DummyCell,
  ]

func mark*[F: TsuField or WaterField](
    nazo: NazoPuyo[F], endStepIndex = -1
): MarkResult {.inline, noinit.} =
  ## Marks the steps in the Nazo Puyo.
  ## If `endStepIndex` is negative, all steps are used.
  ## This function requires that the field is settled.
  if not nazo.goal.isSupported:
    return NotSupport

  let
    calcConnection =
      nazo.goal.kindOpt.isOk and nazo.goal.kindOpt.unsafeValue in {Place, Connection}
    loopCount =
      if endStepIndex in 0 .. nazo.puyoPuyo.steps.len:
        endStepIndex
      else:
        nazo.puyoPuyo.steps.len
  var
    puyoPuyo = nazo.puyoPuyo
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
    if nazo.goal.kindOpt.isOk:
      case nazo.goal.kindOpt.unsafeValue
      of AccumColor:
        popColors.incl moveResult.colors
      of AccumCount:
        let addCount =
          case nazo.goal.color
          of All:
            moveResult.puyoCount
          of GoalColor.Garbages:
            moveResult.garbagesCount
          of Colors:
            moveResult.colorPuyoCount
          else:
            moveResult.cellCount GoalColorToCell[nazo.goal.color]

        popCount.inc addCount
      else:
        discard

    # check clear
    var satisfied =
      if nazo.goal.clearColorOpt.isOk:
        let
          clearColor = nazo.goal.clearColorOpt.unsafeValue
          fieldCount =
            case clearColor
            of All:
              puyoPuyo.field.puyoCount
            of GoalColor.Garbages:
              puyoPuyo.field.garbagesCount
            of Colors:
              puyoPuyo.field.colorPuyoCount
            else:
              puyoPuyo.field.cellCount GoalColorToCell[clearColor]

        fieldCount == 0
      else:
        true

    # check kind-specific
    if nazo.goal.kindOpt.isOk:
      satisfied.assign satisfied and (
        case nazo.goal.kindOpt.unsafeValue
        of Chain:
          nazo.goal.isSatisfiedChain moveResult
        of Color:
          nazo.goal.isSatisfiedColor moveResult
        of Count:
          nazo.goal.isSatisfiedCount moveResult
        of Place:
          nazo.goal.isSatisfiedPlace moveResult
        of Connection:
          nazo.goal.isSatisfiedConnection moveResult
        of AccumColor:
          nazo.goal.isSatisfiedAccumColor popColors
        of AccumCount:
          nazo.goal.isSatisfiedAccumCount popCount
      )

    if satisfied:
      return Accept

    # check dead
    if puyoPuyo.field.isDead:
      return Dead

  WrongAnswer

# ------------------------------------------------
# Nazo Puyo <-> string
# ------------------------------------------------

const GoalPuyoPuyoSep = "\n======\n"

func `$`*[F: TsuField or WaterField](self: NazoPuyo[F]): string {.inline, noinit.} =
  $self.goal & GoalPuyoPuyoSep & $self.puyoPuyo

func parseNazoPuyo*[F: TsuField or WaterField](
    str: string
): StrErrorResult[NazoPuyo[F]] {.inline, noinit.} =
  ## Returns the Nazo Puyo converted from the string representation.
  let
    errorMsg = "Invalid Nazo Puyo: {str}".fmt
    strs = str.split GoalPuyoPuyoSep
  if strs.len != 2:
    return err "Invalid Nazo Puyo: {str}".fmt

  let
    goal = ?strs[0].parseGoal.context errorMsg
    puyoPuyo = ?parsePuyoPuyo[F](strs[1]).context errorMsg

  ok NazoPuyo[F].init(puyoPuyo, goal)

# ------------------------------------------------
# Nazo Puyo <-> URI
# ------------------------------------------------

const
  GoalKey = "goal"
  IshikawaPuyoPuyoGoalSep = "__"

func toUriQueryPon2[F: TsuField or WaterField](
    self: NazoPuyo[F]
): StrErrorResult[string] {.inline, noinit.} =
  ## Returns the URI query converted from the Nazo Puyo.
  let errorMsg = "Nazo Puyo that does not support URI conversion: {self}".fmt

  ok (?self.puyoPuyo.toUriQuery(Pon2).context errorMsg) & '&' &
    [(GoalKey, ?self.goal.toUriQuery(Pon2).context errorMsg)].encodeQuery

func toUriQueryIshikawa[F: TsuField or WaterField](
    self: NazoPuyo[F]
): StrErrorResult[string] {.inline, noinit.} =
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

func toUriQuery*[F: TsuField or WaterField](
    self: NazoPuyo[F], fqdn = Pon2
): StrErrorResult[string] {.inline, noinit.} =
  ## Returns the URI query converted from the Nazo Puyo.
  case fqdn
  of Pon2: self.toUriQueryPon2
  of Ishikawa, Ips: self.toUriQueryIshikawa

func parseNazoPuyoPon2[F: TsuField or WaterField](
    query: string
): StrErrorResult[NazoPuyo[F]] {.inline, noinit.} =
  ## Returns the Nazo Puyo converted from the URI query.
  var
    nazoPuyo = NazoPuyo[F].init
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

  nazoPuyo.puyoPuyo.assign ?parsePuyoPuyo[F](keyVals.encodeQuery, Pon2).context "Invalid Nazo Puyo: {query}".fmt

  ok nazoPuyo

func parseNazoPuyoIshikawa[F: TsuField or WaterField](
    query: string
): StrErrorResult[NazoPuyo[F]] {.inline, noinit.} =
  ## Returns the Nazo Puyo converted from the URI query.
  let
    errorMsg = "Invalid Nazo Puyo: {query}".fmt
    strs = query.rsplit(IshikawaPuyoPuyoGoalSep, 1)
  if strs.len != 2:
    return err errorMsg

  ok NazoPuyo[F].init(
    ?parsePuyoPuyo[F](strs[0], Ishikawa).context errorMsg,
    ?strs[1].parseGoal(Ishikawa).context errorMsg,
  )

func parseNazoPuyo*[F: TsuField or WaterField](
    query: string, fqdn: SimulatorFqdn
): StrErrorResult[NazoPuyo[F]] {.inline, noinit.} =
  ## Returns the Nazo Puyo converted from the URI query.
  case fqdn
  of Pon2:
    parseNazoPuyoPon2[F](query)
  of Ishikawa, Ips:
    parseNazoPuyoIshikawa[F](query)
