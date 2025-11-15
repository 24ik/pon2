## This module implements Nazo Puyo goals.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[setutils, strformat, sugar]
import ./[fqdn]
import ../private/[assign, results2, staticfor, strutils2, tables2]

export results2

type
  GoalKind* {.pure.} = enum
    ## Kind of the goal to clear the nazo puyo.
    Clear = "cぷよ全て消すべし"
    AccColor = "n色消すべし"
    AccColorMore = "n色以上消すべし"
    AccCnt = "cぷよn個消すべし"
    AccCntMore = "cぷよn個以上消すべし"
    Chain = "n連鎖するべし"
    ChainMore = "n連鎖以上するべし"
    ClearChain = "n連鎖&cぷよ全て消すべし"
    ClearChainMore = "n連鎖以上&cぷよ全て消すべし"
    Color = "n色同時に消すべし"
    ColorMore = "n色以上同時に消すべし"
    Cnt = "cぷよn個同時に消すべし"
    CntMore = "cぷよn個以上同時に消すべし"
    Place = "cぷよn箇所同時に消すべし"
    PlaceMore = "cぷよn箇所以上同時に消すべし"
    Conn = "cぷよn連結で消すべし"
    ConnMore = "cぷよn連結以上で消すべし"

  GoalColor* {.pure.} = enum
    ## 'c' in the `GoalKind`.
    All = ""
    Red = "赤"
    Green = "緑"
    Blue = "青"
    Yellow = "黄"
    Purple = "紫"
    Garbages = "おじゃま"
    Colors = "色"

  GoalVal* = int ## 'n' in the `GoalKind`.

  OptGoalColor* = Opt[GoalColor]
  OptGoalVal* = Opt[GoalVal]

  Goal* = object ## Nazo Puyo goal to clear.
    kind*: GoalKind
    optColor*: OptGoalColor
    optVal*: OptGoalVal

const
  NoColorKinds* = {AccColor, AccColorMore, Chain, ChainMore, Color, ColorMore}
    ## All goal kinds not containing 'c'.
  NoValKinds* = {Clear} ## All goal kinds not containing 'n'.

  ColorKinds* = NoColorKinds.complement ## All goal kinds containing 'c'.
  ValKinds* = NoValKinds.complement ## All goal kinds containing 'n'.

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(
    T: type Goal, kind: GoalKind, optColor: OptGoalColor, optVal: OptGoalVal
): T {.inline, noinit.} =
  T(kind: kind, optColor: optColor, optVal: optVal)

func init*(
    T: type Goal, kind: GoalKind, color: GoalColor, val: GoalVal
): T {.inline, noinit.} =
  T.init(kind, OptGoalColor.ok color, OptGoalVal.ok val)

func init*(T: type Goal, kind: GoalKind, color: GoalColor): T {.inline, noinit.} =
  T.init(kind, OptGoalColor.ok color, OptGoalVal.err)

func init*(T: type Goal, kind: GoalKind, val: GoalVal): T {.inline, noinit.} =
  T.init(kind, OptGoalColor.err, OptGoalVal.ok val)

func init*(T: type Goal): T {.inline, noinit.} =
  T.init(Clear, All)

# ------------------------------------------------
# Property
# ------------------------------------------------

func isNormalForm*(self: Goal): bool {.inline, noinit.} =
  ## Returns `true` if the goal is normal form; color and value are set
  ## appropriately.
  (self.kind in ColorKinds == self.optColor.isOk) and
    (self.kind in ValKinds == self.optVal.isOk)

func isSupported*(self: Goal): bool {.inline, noinit.} =
  ## Returns `true` if the goal is supported.
  if self.kind in ColorKinds and self.optColor.isErr:
    return false
  if self.kind in ValKinds and self.optVal.isErr:
    return false

  not (
    self.kind in {Place, PlaceMore, Conn, ConnMore} and
    self.optColor.unsafeValue == Garbages
  )

# ------------------------------------------------
# Normalize
# ------------------------------------------------

const
  DefColor = All
  DefVal = 0.GoalVal

func normalize*(self: var Goal) {.inline, noinit.} =
  ## Normalizes the goal; removes unnecessary color and value and compensates
  ## for missing color and value.
  if self.kind in ColorKinds:
    self.optColor.isOkOr:
      self.optColor.ok DefColor
  else:
    self.optColor.isErrOr:
      self.optColor.err

  if self.kind in ValKinds:
    self.optVal.isOkOr:
      self.optVal.ok DefVal
  else:
    self.optVal.isErrOr:
      self.optVal.err

func normalized*(self: Goal): Goal {.inline, noinit.} =
  ## Returns the normalized goal.
  self.dup normalize

# ------------------------------------------------
# Goal <-> string
# ------------------------------------------------

func initStrToKinds(): array[GoalColor, Table[string, GoalKind]] {.inline, noinit.} =
  ## Returns `StrToKinds`.
  var strToKinds: array[GoalColor, Table[string, GoalKind]]
  staticFor(color, GoalColor):
    let strToKind = collect:
      for kind in GoalKind:
        {($kind).replace("c", $color): kind}
    {.push warning[Uninit]: off.}
    strToKinds[color].assign strToKind
    {.pop.}

  strToKinds

const StrToKinds = initStrToKinds()

func `$`*(self: Goal): string {.inline, noinit.} =
  var replacements = newSeqOfCap[(string, string)](2)
  if self.optColor.isOk:
    replacements.add ("c", $self.optColor.unsafeValue)
  if self.optVal.isOk:
    replacements.add ("n", $self.optVal.unsafeValue)

  ($self.kind).multiReplace replacements

func parseGoal*(str: string): Res[Goal] {.inline, noinit.} =
  ## Returns the goal converted from the string representation.
  var
    goal = Goal.init(GoalKind.low, OptGoalColor.err, OptGoalVal.err)
    str2 = str

  # value
  for charIdx, c in str2:
    if not (
      c.isDigit or (c == '-' and charIdx.succ < str2.len and str2[charIdx.succ].isDigit)
    ):
      continue

    var i = charIdx.succ
    while i < str2.len and str2[i].isDigit:
      i.inc

    let valStr = str2[charIdx ..< i]
    goal.optVal.ok ?valStr.parseIntRes.context "Invalid goal (val): {str}".fmt
    str2.assign str2.replace(valStr, "n")
    break

  # kind, color
  # NOTE: no-color kind is captured by All-color kinds
  var kindFound = false
  for c, strToKind in StrToKinds:
    if str2 in strToKind:
      kindFound = true
      goal.optColor.ok c
      goal.kind.assign strToKind.getRes(str2).unsafeValue

      break
  if not kindFound:
    return err "Invalid goal: {str}".fmt

  # we cannot distinguish '' between the All-color and the empty,
  # so postprocesses here just like a normalization
  if goal.kind in NoColorKinds and goal.optColor.isOk:
    goal.optColor.err

  ok goal

# ------------------------------------------------
# Goal <-> URI
# ------------------------------------------------

const
  QuerySep = "_"
  EmptyColor = ""
  EmptyVal = ""
  KindToIshikawaUri = "2abcduvwxEFGHIJQR"
  ColorToIshikawaUri = "01234567"
  ValToIshikawaUri = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-"
  EmptyIshikawaUri = '0'

  IshikawaUriToKind = collect:
    for kind in GoalKind:
      {KindToIshikawaUri[kind.ord]: kind}
  IshikawaUriToColor = collect:
    for color in GoalColor:
      {ColorToIshikawaUri[color.ord]: color}
  IshikawaUriToVal = collect:
    for i, uri in ValToIshikawaUri:
      {uri: i.GoalVal}

func toUriQuery*(self: Goal, fqdn = Pon2): Res[string] {.inline, noinit.} =
  ## Returns the URI query converted from the requirement.
  case fqdn
  of Pon2:
    let queries = [
      $self.kind.ord,
      if self.optColor.isOk:
        $self.optColor.unsafeValue.ord
      else:
        EmptyColor,
      if self.optVal.isOk:
        $self.optVal.unsafeValue
      else:
        EmptyVal,
    ]
    ok queries.join QuerySep
  of Ishikawa, Ips:
    if self.optVal.isOk and self.optVal.unsafeValue notin 0 ..< ValToIshikawaUri.len:
      err "Ishikawa/Ips format only supports the val in [0, 63], but got {self.optVal.unsafeValue}".fmt
    else:
      let
        kindChar = KindToIshikawaUri[self.kind.ord]
        colorChar =
          if self.optColor.isOk:
            ColorToIshikawaUri[self.optColor.unsafeValue.ord]
          else:
            EmptyIshikawaUri
        valChar =
          if self.optVal.isOk:
            ValToIshikawaUri[self.optVal.unsafeValue]
          else:
            EmptyIshikawaUri

      ok "{kindChar}{colorChar}{valChar}".fmt

func parseGoal*(query: string, fqdn: SimulatorFqdn): Res[Goal] {.inline, noinit.} =
  ## Returns the goal converted from the URI query.
  var goal = Goal.init(GoalKind.low, OptGoalColor.err, OptGoalVal.err)

  case fqdn
  of Pon2:
    if query == "":
      return ok Goal.init

    let strs = query.split QuerySep
    if strs.len != 3:
      return err "Invalid goal: {query}".fmt

    let kindInt = ?strs[0].parseIntRes.context "Invalid goal (kind): {query}".fmt
    if kindInt notin GoalKind.low.ord .. GoalKind.high.ord:
      return err "Invalid goal (kind): {query}".fmt
    goal.kind.assign kindInt.GoalKind

    if strs[1] != EmptyColor:
      let colorInt = ?strs[1].parseIntRes.context "Invalid goal (color): {query}".fmt
      if colorInt notin GoalColor.low.ord .. GoalColor.high.ord:
        return err "Invalid goal (color): {query}".fmt
      goal.optColor.ok colorInt.GoalColor

    if strs[2] != EmptyVal:
      let valInt = ?strs[2].parseIntRes.context "Invalid goal (val): {query}".fmt
      goal.optVal.ok valInt.GoalVal
  of Ishikawa, Ips:
    if query.len != 3:
      return err "Invalid goal: {query}".fmt

    goal.kind.assign ?IshikawaUriToKind.getRes(query[0]).context "Invalid goal (kind): {query}".fmt
    goal.optColor.ok ?IshikawaUriToColor.getRes(query[1]).context "Invalid goal (color): {query}".fmt
    goal.optVal.ok ?IshikawaUriToVal.getRes(query[2]).context "Invalid goal (val): {query}".fmt

    # we cannot distinguish '0' between the valid color/val and the empty,
    # so postprocesses here just like a normalization
    if goal.kind in NoColorKinds and query[1] == EmptyIshikawaUri:
      goal.optColor.err
    if goal.kind in NoValKinds and query[2] == EmptyIshikawaUri:
      goal.optVal.err

  ok goal
