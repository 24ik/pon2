## This module implements Nazo Puyo goals.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[setutils, strformat, sugar]
import ./[fqdn]
import ../private/[assign3, results2, strutils2, tables2]

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
    Garbage = "おじゃま"
    Color = "色"

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
): T {.inline.} =
  T(kind: kind, optColor: optColor, optVal: optVal)

func init*(T: type Goal, kind: GoalKind, color: GoalColor, val: GoalVal): T {.inline.} =
  T.init(kind, OptGoalColor.ok color, OptGoalVal.ok val)

func init*(T: type Goal, kind: GoalKind, color: GoalColor): T {.inline.} =
  T.init(kind, OptGoalColor.ok color, OptGoalVal.err)

func init*(T: type Goal, kind: GoalKind, val: GoalVal): T {.inline.} =
  T.init(kind, OptGoalColor.err, OptGoalVal.ok val)

# ------------------------------------------------
# Property
# ------------------------------------------------

func isNormalForm*(self: Goal): bool {.inline.} =
  ## Returns `true` if the goal is normal form; color and value are set
  ## appropriately.
  (self.kind in ColorKinds == self.optColor.isOk) and
    (self.kind in ValKinds == self.optVal.isOk)

func isSupported*(self: Goal): bool {.inline.} =
  ## Returns `true` if the goal is supported.
  if self.kind in ColorKinds and self.optColor.isErr:
    return false
  if self.kind in ValKinds and self.optVal.isErr:
    return false

  not (
    self.kind in {Place, PlaceMore, Conn, ConnMore} and self.optColor.expect == Garbage
  )

# ------------------------------------------------
# Normalize
# ------------------------------------------------

const
  DefColor = All
  DefVal = 0.GoalVal

func normalize*(self: var Goal) {.inline.} =
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

func normalized*(self: Goal): Goal {.inline.} =
  ## Returns the normalized goal.
  self.dup normalize

# ------------------------------------------------
# Goal <-> string
# ------------------------------------------------

const StrToKind = collect:
  for kind in GoalKind:
    {$kind: kind}

func `$`*(self: Goal): string {.inline.} =
  var replacements = newSeqOfCap[(string, string)](2)
  if self.optColor.isOk:
    replacements.add ("c", $self.optColor.expect)
  if self.optVal.isOk:
    replacements.add ("n", $self.optVal.expect)

  ($self.kind).multiReplace replacements

func parseGoal*(str: string): Res[Goal] {.inline.} =
  ## Returns the goal converted from the string representation.
  var
    goal = Goal.init(GoalKind.low, Opt[GoalColor].err, Opt[GoalVal].err)
    str2 = str

  for color in GoalColor:
    if color == All:
      continue

    if $color in str2:
      str2.assign str2.replace($color, "c")
      goal.optColor.ok color
      break

  var
    inDigit = false
    digits = newSeq[char]()
  for c in str2:
    if c.isDigit:
      inDigit.assign true
      digits.add c
    elif inDigit:
      var valStr = newStringOfCap digits.len
      for d in digits:
        valStr.add d

      goal.optVal.ok GoalVal ?valStr.parseIntRes.context "Invalid goal (val): {str}".fmt
      str2.assign str2.replace(valStr, "n")
      break

  goal.kind.assign ?StrToKind.getRes(str2).context "Invalid goal: {str}".fmt

  # we cannot distinguish empty string between Kind.All and no-color kind,
  # so postprocesses here just like a normalization
  if goal.optColor.isErr and goal.kind in ColorKinds:
    goal.optColor.ok All

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

func toUriQuery*(self: Goal, fqdn = Pon2): Res[string] {.inline.} =
  ## Returns the URI query converted from the requirement.
  case fqdn
  of Pon2:
    let queries = [
      $self.kind.ord,
      if self.optColor.isOk:
        $self.optColor.expect.ord
      else:
        EmptyColor,
      if self.optVal.isOk:
        $self.optVal.expect
      else:
        EmptyVal,
    ]
    ok queries.join QuerySep
  of Ishikawa, Ips:
    if self.optVal.isOk and self.optVal.expect notin 0 ..< ValToIshikawaUri.len:
      err "Ishikawa/Ips format only supports the val in [0, 63], but got {self.optVal.expect}".fmt
    else:
      let
        kindChar = KindToIshikawaUri[self.kind.ord]
        colorChar =
          if self.optColor.isOk:
            ColorToIshikawaUri[self.optColor.expect.ord]
          else:
            EmptyIshikawaUri
        valChar =
          if self.optVal.isOk:
            ValToIshikawaUri[self.optVal.expect]
          else:
            EmptyIshikawaUri

      ok "{kindChar}{colorChar}{valChar}".fmt

func parseGoal*(query: string, fqdn: IdeFqdn): Res[Goal] {.inline.} =
  ## Returns the goal converted from the URI query.
  var goal = Goal.init(GoalKind.low, Opt[GoalColor].err, Opt[GoalVal].err)

  case fqdn
  of Pon2:
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
