## This module implements Nazo Puyo.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, typetraits, uri]
import ./[field, fqdn, goal, moveresult, pair, placement, popresult, puyopuyo, step]
import ../private/[bitops3, macros2, results2, strutils2, tables2]

type NazoPuyo*[F: TsuField or WaterField] = object ## Nazo Puyo.
  puyoPuyo*: PuyoPuyo[F]
  goal*: Goal

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const DefaultGoal = Goal.init(Clear, All)

func init*[F: TsuField or WaterField](T: type NazoPuyo[F]): T {.inline.} =
  T(puyoPuyo: PuyoPuyo[F].init, goal: DefaultGoal)

func init*[F: TsuField or WaterField](
    T: type NazoPuyo[F], puyoPuyo: PuyoPuyo[F], goal: Goal
): T {.inline.} =
  T(puyoPuyo: puyoPuyo, goal: goal)

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
  let strs = str.split GoalPuyoPuyoSep
  if strs.len != 2:
    return err "Invalid Nazo Puyo: {str}".fmt

  let
    errMsg = "Invalid Nazo Puyo: {str}".fmt
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
  let strs = query.split PuyoPuyoGoalIshikawaSep
  if strs.len != 2:
    return err "Invalid Nazo Puyo: {query}".fmt

  ok NazoPuyo[F].init(
    ?parsePuyoPuyo[F](strs[0], Ishikawa), ?strs[1].parseGoal(Ishikawa)
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
