## This module implements Nazo Puyo goals.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[options, setutils, strformat, strutils, sugar, tables, uri]
import results
import ./[fqdn]
import ../private/[assign2, misc]

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

  Goal* = object ## Nazo Puyo goal to clear.
    kind*: GoalKind
    color*: Opt[GoalColor]
    val*: Opt[GoalVal]

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
    T: type Goal, kind: GoalKind, color: Opt[GoalColor], val: Opt[GoalVal]
): T {.inline.} =
  T(kind: kind, color: color, val: val)

func init*(T: type Goal, kind: GoalKind, color: GoalColor, val: GoalVal): T {.inline.} =
  T(kind: kind, color: Opt[GoalColor].ok color, val: Opt[GoalVal].ok val)

func init*(T: type Goal, kind: GoalKind, color: GoalColor): T {.inline.} =
  T(kind: kind, color: Opt[GoalColor].ok color, val: Opt[GoalVal].err)

func init*(T: type Goal, kind: GoalKind, val: GoalVal): T {.inline.} =
  T(kind: kind, color: Opt[GoalColor].err, val: Opt[GoalVal].ok val)

# ------------------------------------------------
# Property
# ------------------------------------------------

func isNormalForm*(self: Goal): bool {.inline.} =
  ## Returns `true` if the goal is normal form; color and value are set
  ## appropriately.
  if self.kind in ColorKinds != self.color.isOk:
    return false
  if self.kind in ValKinds != self.val.isOk:
    return false

  true

func isSupported*(self: Goal): bool {.inline.} =
  ## Returns `true` if the goal is supported.
  if self.kind in ColorKinds and self.color.isErr:
    return false
  if self.kind in ValKinds and self.val.isErr:
    return false

  self.kind notin {Place, PlaceMore, Conn, ConnMore} or
    self.color != Opt[GoalColor].ok Garbage

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
    if self.color.isErr:
      self.color.assign Opt[GoalColor].ok DefColor
  else:
    if self.color.isOk:
      self.color.assign Opt[GoalColor].err

  if self.kind in ValKinds:
    if self.val.isNone:
      self.val.assign Opt[GoalVal].ok DefVal
  else:
    if self.val.isOk:
      self.val.assign Opt[GoalVal].err

func normalized*(self: Goal): Goal {.inline.} =
  ## Returns the normalized goal.
  self.dup(normalize)

# ------------------------------------------------
# Goal <-> string
# ------------------------------------------------

const StrToKind = collect:
  for kind in GoalKind:
    {$kind: kind}

func `$`*(self: Goal): string {.inline.} =
  var replacements = newSeqOfCap[(string, string)](2)
  if self.color.isOk:
    replacements.add ("c", $self.color.value)
  if self.val.isOk:
    replacements.add ("n", $self.val.value)

  ($self.kind).multiReplace replacements

func parseGoal*(str: string): Result[Goal, string] {.inline.} =
  ## Returns the goal converted from the string representation.
  var
    goalColor = Opt[GoalColor].err
    goalVal = Opt[GoalVal].err
    str2 = str

  for color in GoalColor:
    if color != All and $color in str2:
      str2.assign str2.replace($color, "c")
      goalColor.assign Opt[GoalColor].ok color
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

      let valRes = valStr.parseIntRes
      if valRes.isOk:
        goalVal.assign Opt[GoalVal].ok valRes.value
        str2.assign str2.replace($valRes.value, "n")

  let kindRes = StrToKind.getRes str2
  if kindRes.isOk:
    Result[Goal, string].ok Goal.init(kindRes.value, goalColor, goalVal)
  else:
    Result[Goal, string].err "Invalid goal: {str}".fmt

# ------------------------------------------------
# Goal <-> URI
# ------------------------------------------------

const
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

  KindKey = "goalkind"
  ColorKey = "goalcolor"
  ValKey = "goalval"

  GoalUriQueryKeys* = [KindKey, ColorKey, ValKey]

func toUriQuery*(self: Goal, fqdn = Pon2): Result[string, string] {.inline.} =
  ## Returns the URI query converted from the requirement.
  case fqdn
  of Pon2:
    var queries = @[(KindKey, $self.kind.ord)]
    if self.color.isOk:
      queries.add (ColorKey, $self.color.value.ord)
    if self.val.isOk:
      queries.add (ValKey, $self.val.value)

    Result[string, string].ok queries.encodeQuery
  of Ishikawa, Ips:
    if self.val.isOk and self.val.get notin 0 ..< ValToIshikawaUri.len:
      Result[string, string].err(
        "Goal value not in [0, 63] does not support with Ishikawa/Ips format."
      )
    else:
      let
        kindChar = KindToIshikawaUri[self.kind.ord]
        colorChar =
          if self.color.isOk:
            ColorToIshikawaUri[self.color.value.ord]
          else:
            EmptyIshikawaUri
        valChar =
          if self.val.isOk:
            ValToIshikawaUri[self.val.get]
          else:
            EmptyIshikawaUri

      Result[string, string].ok "{kindChar}{colorChar}{valChar}".fmt

func parseGoal*(query: string, fqdn: IdeFqdn): Result[Goal, string] {.inline.} =
  ## Returns the goal converted from the URI query.
  var
    goal = Goal.init(GoalKind.low, Opt[GoalColor].err, Opt[GoalVal].err)
    kindSet = false
    colorSet = false
    valSet = false

  case fqdn
  of Pon2:
    for (key, val) in query.decodeQuery:
      case key
      of KindKey:
        if kindSet:
          return Result[Goal, string].err "Invalid goal (kind): {query}".fmt

        let kindIntRes = val.parseIntRes
        if kindIntRes.isErr or
            kindIntRes.value notin GoalKind.low.ord .. GoalKind.high.ord:
          return Result[Goal, string].err "Invalid goal (kind): {query}".fmt

        goal.kind.assign kindIntRes.value.GoalKind
        kindSet.assign true
      of ColorKey:
        if colorSet:
          return Result[Goal, string].err "Invalid goal (color): {query}".fmt

        let colorIntRes = val.parseIntRes
        if colorIntRes.isErr or
            colorIntRes.value notin GoalColor.low.ord .. GoalColor.high.ord:
          return Result[Goal, string].err "Invalid goal (color): {query}".fmt

        goal.color.assign Opt[GoalColor].ok colorIntRes.value.GoalColor
        colorSet.assign true
      of ValKey:
        if valSet:
          return Result[Goal, string].err "Invalid goal (val): {query}".fmt

        let valIntRes = val.parseIntRes
        if valIntRes.isErr:
          return Result[Goal, string].err "Invalid goal (val): {query}".fmt

        goal.val.assign Opt[GoalVal].ok valIntRes.value
        valSet.assign true
      else:
        return Result[Goal, string].err "Invalid goal: {query}".fmt
  of Ishikawa, Ips:
    if query.len != 3:
      return Result[Goal, string].err "Invalid goal: {query}".fmt

    let
      kindRes = IshikawaUriToKind.getRes query[0]
      colorRes = IshikawaUriToColor.getRes query[1]
      valRes = IshikawaUriToVal.getRes query[2]

    if kindRes.isErr:
      return Result[Goal, string].err "Invalid goal (kind): {query}".fmt
    if colorRes.isErr and query[1] != EmptyIshikawaUri:
      return Result[Goal, string].err "Invalid goal (color): {query}".fmt
    if valRes.isErr and query[2] != EmptyIshikawaUri:
      return Result[Goal, string].err "Invalid goal (val): {query}".fmt

    goal.kind.assign kindRes.value
    goal.color.assign colorRes.optValue
    goal.val.assign valRes.optValue

    # we cannot distinguish '0' between the valid color/val and the empty,
    # so postprocesses here just like a normalization
    if kindRes.value in NoColorKinds and query[1] == EmptyIshikawaUri:
      goal.color.assign Opt[GoalColor].err
    if kindRes.value in NoValKinds and query[2] == EmptyIshikawaUri:
      goal.val.assign Opt[GoalVal].err

  Result[Goal, string].ok goal
