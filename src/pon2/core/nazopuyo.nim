## This module implements Nazo Puyo.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, typetraits, uri]
import
  ./[cell, field, fqdn, goal, moveresult, pair, placement, popresult, puyopuyo, step]
import ../private/[assign3, bitops3, macros2, results2, strutils2, tables2]
import ../private/core/[nazopuyo]

export results2

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
): T {.inline.} =
  T(puyoPuyo: puyoPuyo, goal: goal)

func init*[F: TsuField or WaterField](T: type NazoPuyo[F]): T {.inline.} =
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

func mark*[F: TsuField or WaterField](nazo: NazoPuyo[F]): MarkResult {.inline.} =
  ## Marks the steps in the Nazo Puyo.
  ## This function requires that the field is settled.
  if not nazo.goal.isSupported:
    return NotSupport

  let calcConn = nazo.goal.kind in {Place, PlaceMore, Conn, ConnMore}
  var
    puyoPuyo = nazo.puyoPuyo
    skipped = false
    popColors = set[Cell]({}) # used by AccColor[More]
    popCnt = 0 # used by AccCnt[More]

  while puyoPuyo.steps.len > 0:
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
    of StepKind.Garbages:
      discard

    let moveRes = puyoPuyo.move calcConn

    # update accumulative results
    case nazo.goal.kind
    of AccColor, AccColorMore:
      popColors.incl moveRes.colors
    of AccCnt, AccCntMore:
      let addCnt =
        case nazo.goal.optColor.unsafeValue
        of All:
          moveRes.puyoCnt
        of GoalColor.Garbages:
          moveRes.garbagesCnt
        of Colors:
          moveRes.colorPuyoCnt
        else:
          moveRes.cellCnt GoalColorToCell[nazo.goal.optColor.unsafeValue]

      popCnt.inc addCnt
    else:
      discard

    # check clear
    var satisfied =
      if nazo.goal.kind in {Clear, ClearChain, ClearChainMore}:
        let fieldCnt =
          case nazo.goal.optColor.unsafeValue
          of All:
            puyoPuyo.field.puyoCnt
          of GoalColor.Garbages:
            puyoPuyo.field.garbagesCnt
          of Colors:
            puyoPuyo.field.colorPuyoCnt
          else:
            puyoPuyo.field.cellCnt GoalColorToCell[nazo.goal.optColor.unsafeValue]

        fieldCnt == 0
      else:
        true

    # check kind-specific
    satisfied.assign satisfied and (
      case nazo.goal.kind
      of Clear:
        true
      of AccColor:
        nazo.goal.isSatisfiedAccColor(popColors, AccColor)
      of AccColorMore:
        nazo.goal.isSatisfiedAccColor(popColors, AccColorMore)
      of AccCnt:
        nazo.goal.isSatisfiedAccCnt(popCnt, AccCnt)
      of AccCntMore:
        nazo.goal.isSatisfiedAccCnt(popCnt, AccCntMore)
      of Chain:
        nazo.goal.isSatisfiedChain(moveRes, Chain)
      of ChainMore:
        nazo.goal.isSatisfiedChain(moveRes, ChainMore)
      of ClearChain:
        nazo.goal.isSatisfiedChain(moveRes, ClearChain)
      of ClearChainMore:
        nazo.goal.isSatisfiedChain(moveRes, ClearChainMore)
      of Color:
        nazo.goal.isSatisfiedColor(moveRes, Color)
      of ColorMore:
        nazo.goal.isSatisfiedColor(moveRes, ColorMore)
      of Cnt:
        nazo.goal.isSatisfiedCnt(moveRes, Cnt)
      of CntMore:
        nazo.goal.isSatisfiedCnt(moveRes, CntMore)
      of Place:
        nazo.goal.isSatisfiedPlace(moveRes, Place)
      of PlaceMore:
        nazo.goal.isSatisfiedPlace(moveRes, PlaceMore)
      of Conn:
        nazo.goal.isSatisfiedConn(moveRes, Conn)
      of ConnMore:
        nazo.goal.isSatisfiedConn(moveRes, ConnMore)
    )

    if satisfied:
      return Accept

    # check dead
    if puyoPuyo.field.isDead:
      return Dead

  return WrongAnswer

# ------------------------------------------------
# Nazo Puyo <-> string
# ------------------------------------------------

const GoalPuyoPuyoSep = "\n======\n"

func `$`*[F: TsuField or WaterField](self: NazoPuyo[F]): string {.inline.} =
  $self.goal & GoalPuyoPuyoSep & $self.puyoPuyo

func parseNazoPuyo*[F: TsuField or WaterField](
    str: string
): Res[NazoPuyo[F]] {.inline.} =
  ## Returns the Nazo Puyo converted from the string representation.
  let
    errMsg = "Invalid Nazo Puyo: {str}".fmt
    strs = str.split GoalPuyoPuyoSep
  if strs.len != 2:
    return err "Invalid Nazo Puyo: {str}".fmt

  let
    goal = ?strs[0].parseGoal.context errMsg
    puyoPuyo = ?parsePuyoPuyo[F](strs[1]).context errMsg

  ok NazoPuyo[F].init(puyoPuyo, goal)

# ------------------------------------------------
# Nazo Puyo <-> URI
# ------------------------------------------------

const
  GoalKey = "goal"
  PuyoPuyoGoalIshikawaSep = "__"

func toUriQueryPon2[F: TsuField or WaterField](
    self: NazoPuyo[F]
): Res[string] {.inline.} =
  ## Returns the URI query converted from the Nazo Puyo.
  ok (?self.puyoPuyo.toUriQuery Pon2) & '&' &
    [(GoalKey, ?self.goal.toUriQuery Pon2)].encodeQuery

func toUriQueryIshikawa[F: TsuField or WaterField](
    self: NazoPuyo[F]
): Res[string] {.inline.} =
  ## Returns the URI query converted from the Nazo Puyo.
  ok (?self.puyoPuyo.toUriQuery Ishikawa) & PuyoPuyoGoalIshikawaSep &
    (?self.goal.toUriQuery Ishikawa)

func toUriQuery*[F: TsuField or WaterField](
    self: NazoPuyo[F], fqdn = Pon2
): Res[string] {.inline.} =
  ## Returns the URI query converted from the Nazo Puyo.
  case fqdn
  of Pon2: self.toUriQueryPon2
  of Ishikawa, Ips: self.toUriQueryIshikawa

func parseNazoPuyoPon2[F: TsuField or WaterField](
    query: string
): Res[NazoPuyo[F]] {.inline.} =
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

      goalSet = true
      nazoPuyo.goal = ?val.parseGoal(Pon2).context "Invalid Nazo Puyo: {query}".fmt
    else:
      keyVals.add (key, val)

  if not goalSet:
    const GoalKey2 = GoalKey # strformat needs this
    return err "Invalid Nazo Puyo (missing `{GoalKey2}`): {query}".fmt

  nazoPuyo.puyoPuyo =
    ?parsePuyoPuyo[F](keyVals.encodeQuery, Pon2).context "Invalid Nazo Puyo: {query}".fmt

  ok nazoPuyo

func parseNazoPuyoIshikawa[F: TsuField or WaterField](
    query: string
): Res[NazoPuyo[F]] {.inline.} =
  ## Returns the Nazo Puyo converted from the URI query.
  let
    errMsg = "Invalid Nazo Puyo: {query}".fmt
    strs = query.split PuyoPuyoGoalIshikawaSep
  if strs.len != 2:
    return err errMsg

  ok NazoPuyo[F].init(
    ?parsePuyoPuyo[F](strs[0], Ishikawa).context errMsg,
    ?strs[1].parseGoal(Ishikawa).context errMsg,
  )

func parseNazoPuyo*[F: TsuField or WaterField](
    query: string, fqdn: IdeFqdn
): Res[NazoPuyo[F]] {.inline.} =
  ## Returns the Nazo Puyo converted from the URI query.
  case fqdn
  of Pon2:
    parseNazoPuyoPon2[F](query)
  of Ishikawa, Ips:
    parseNazoPuyoIshikawa[F](query)
