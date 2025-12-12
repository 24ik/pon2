## This module implements Nazo Puyo goals.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[setutils, strformat, sugar]
import ./[fqdn]
import ../[utils]
import ../private/[assign, strutils, tables]

export utils

type
  GoalKind* {.pure.} = enum
    ## Kind of the goal to clear the Nazo Puyo.
    Chain
    Color
    Count
    Place
    Connection
    AccumColor
    AccumCount

  GoalColor* {.pure.} = enum
    ## Color in the goal.
    All = ""
    Nuisance = "おじゃま"
    Colored = "色"
    Red = "赤"
    Green = "緑"
    Blue = "青"
    Yellow = "黄"
    Purple = "紫"

  GoalValOperator* {.pure.} = enum
    ## Operator used in a value comparison.
    Exact = "ちょうど"
    AtLeast = "以上"

  GoalMain* = object ## Main part of the Nazo Puyo goal.
    kind*: GoalKind
    color*: GoalColor
    val*: int
    valOperator*: GoalValOperator

  Goal* = object ## Nazo Puyo goal.
    mainOpt*: Opt[GoalMain]
    clearColorOpt*: Opt[GoalColor]

const
  ColorKinds* = {Count, Place, Connection, AccumCount}
  NoColorKinds* = ColorKinds.complement

  NoneGoalMain* = Opt[GoalMain].err
  NoneGoalColor* = Opt[GoalColor].err
  NoneGoal* = Goal(mainOpt: NoneGoalMain, clearColorOpt: NoneGoalColor)

  DefaultColor = GoalColor.low

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(
    T: type GoalMain,
    kind: GoalKind,
    color: GoalColor,
    val: int,
    valOperator: GoalValOperator,
): T {.inline, noinit.} =
  T(kind: kind, color: color, val: val, valOperator: valOperator)

func init*(
    T: type GoalMain, kind: GoalKind, val: int, valOperator: GoalValOperator
): T {.inline, noinit.} =
  T.init(kind, DefaultColor, val, valOperator)

func init*(
    T: type Goal,
    kind: GoalKind,
    color: GoalColor,
    val: int,
    valOperator: GoalValOperator,
    clearColorOpt = NoneGoalColor,
): T {.inline, noinit.} =
  T(
    mainOpt: Opt[GoalMain].ok GoalMain.init(kind, color, val, valOperator),
    clearColorOpt: clearColorOpt,
  )

func init*(
    T: type Goal,
    kind: GoalKind,
    val: int,
    valOperator: GoalValOperator,
    clearColorOpt = NoneGoalColor,
): T {.inline, noinit.} =
  T.init(kind, DefaultColor, val, valOperator, clearColorOpt)

func init*(
    T: type Goal,
    kind: GoalKind,
    color: GoalColor,
    val: int,
    valOperator: GoalValOperator,
    clearColor: GoalColor,
): T {.inline, noinit.} =
  T.init(kind, color, val, valOperator, Opt[GoalColor].ok clearColor)

func init*(
    T: type Goal,
    kind: GoalKind,
    val: int,
    valOperator: GoalValOperator,
    clearColor: GoalColor,
): T {.inline, noinit.} =
  T.init(kind, DefaultColor, val, valOperator, clearColor)

func init*(T: type Goal, clearColorOpt = NoneGoalColor): T {.inline, noinit.} =
  T(mainOpt: NoneGoalMain, clearColorOpt: clearColorOpt)

func init*(T: type Goal, clearColor: GoalColor): T {.inline, noinit.} =
  T.init(Opt[GoalColor].ok clearColor)

# ------------------------------------------------
# Property
# ------------------------------------------------

func isSupported*(self: Goal): bool {.inline, noinit.} =
  ## Returns `true` if the goal is supported.
  if self.mainOpt.isOk:
    let main = self.mainOpt.unsafeValue
    not (main.kind in {Place, Connection} and main.color == Nuisance)
  else:
    self.clearColorOpt.isOk

# ------------------------------------------------
# Normalize
# ------------------------------------------------

func isNormalized*(self: Goal): bool {.inline, noinit.} =
  ## Returns `true` if the goal is normalized.
  if self.mainOpt.isErr:
    return true
  let main = self.mainOpt.unsafeValue

  not (main.kind notin ColorKinds and main.color != DefaultColor)

func normalize*(self: var Goal) {.inline, noinit.} =
  ## Normalizes the goal.
  if self.mainOpt.isErr:
    return
  let main = self.mainOpt.unsafeValue

  if main.kind in NoColorKinds:
    self.mainOpt.unsafeValue.color.assign DefaultColor

func normalized*(self: Goal): Goal {.inline, noinit.} =
  ## Returns the normalized goal.
  self.dup normalize

# ------------------------------------------------
# Goal <-> string
# ------------------------------------------------

const
  GoalSuffix = "べし"
  GoalSep = '&'

  ExactPlaceholder = "<EXACT>"
  AtLeastPlaceholder = "<ATLEAST>"
  ExactStr = "ちょうど"
  AtLeastStr = "以上"

  GoalKindStrs: array[GoalKind, string] = [
    "{ExactPlaceholder}n連鎖{AtLeastPlaceholder}する".fmt,
    "{ExactPlaceholder}n色{AtLeastPlaceholder}同時に消す".fmt,
    "cぷよ{ExactPlaceholder}n個{AtLeastPlaceholder}同時に消す".fmt,
    "cぷよ{ExactPlaceholder}n箇所{AtLeastPlaceholder}で同時に消す".fmt,
    "cぷよ{ExactPlaceholder}n連結{AtLeastPlaceholder}で消す".fmt,
    "累計{ExactPlaceholder}n色{AtLeastPlaceholder}消す".fmt,
    "cぷよ累計{ExactPlaceholder}n個{AtLeastPlaceholder}消す".fmt,
  ]
  ClearStr = "cぷよ全て消す"
  NoneGoalStr = "クリア条件未設定"

func `$`*(self: Goal): string {.inline, noinit.} =
  if self == NoneGoal:
    return $NoneGoalStr

  let
    mainStr =
      if self.mainOpt.isOk:
        let main = self.mainOpt.unsafeValue

        var replacer = @[("c", $main.color), ("n", $main.val)]
        case main.valOperator
        of Exact:
          replacer.add (ExactPlaceholder, ExactStr)
          replacer.add (AtLeastPlaceholder, "")
        of AtLeast:
          replacer.add (ExactPlaceholder, "")
          replacer.add (AtLeastPlaceholder, AtLeastStr)

        GoalKindStrs[main.kind].multiReplace replacer
      else:
        ""
    clearStr =
      if self.clearColorOpt.isOk:
        let clearColor = self.clearColorOpt.unsafeValue

        ClearStr.replace("c", $clearColor)
      else:
        ""

  "{mainStr}{GoalSep}{clearStr}".fmt.strip(chars = {GoalSep}) & GoalSuffix

func parseGoal*(str: string): Pon2Result[Goal] {.inline, noinit.} =
  ## Returns the goal converted from the string representation.
  let errorMsg = "Invalid goal: {str}".fmt

  # none goal
  if str in ["", $NoneGoalStr]:
    return ok NoneGoal

  if not str.endsWith GoalSuffix:
    return err errorMsg

  let strs = str.replace(GoalSuffix, "").split GoalSep
  if strs.len > 2:
    return err errorMsg

  # clearColor
  var clearColorOpt = NoneGoalColor
  for color in GoalColor:
    if ClearStr.replace("c", $color) in strs:
      clearColorOpt.ok color
      break
  if strs.len == 1 and clearColorOpt.isOk:
    return ok Goal.init clearColorOpt

  # operator
  var
    valOperator = GoalValOperator.low
    kindStr = strs[0]
  if ExactStr in strs[0]:
    valOperator.assign Exact
    kindStr.assign strs[0].replace(ExactStr, "")
  elif AtLeastStr in strs[0]:
    valOperator.assign AtLeast
    kindStr.assign strs[0].replace(AtLeastStr, "")
  else:
    return err errorMsg

  # val
  # TODO: regex
  var
    valOpt = Opt[int].err
    kindStrNoVal = kindStr
  for charIndex, c in kindStr:
    if not (
      c.isDigit or
      (c == '-' and charIndex + 1 < kindStr.len and kindStr[charIndex + 1].isDigit)
    ):
      continue

    var endIndex = charIndex + 1
    while endIndex < kindStr.len and kindStr[endIndex].isDigit:
      endIndex.inc

    let valStr = kindStr[charIndex ..< endIndex]
    valOpt.ok ?valStr.parseInt.context errorMsg
    kindStrNoVal.assign kindStr.replace(valStr, "")
    break
  if valOpt.isErr:
    return err errorMsg
  let val = valOpt.unsafeValue

  # color
  var
    color = DefaultColor
    kindStrNoValColor = kindStrNoVal
  for goalColor in GoalColor:
    let colorStr = "{goalColor}ぷよ".fmt
    if kindStrNoVal.startsWith colorStr:
      color.assign goalColor
      kindStrNoValColor.assign kindStrNoVal.replace(colorStr, "")
      break

  # kind
  var kind = GoalKind.low
  case kindStrNoValColor
  of "連鎖する":
    kind.assign Chain
  of "色同時に消す":
    kind.assign GoalKind.Color
  of "個同時に消す":
    kind.assign Count
  of "箇所で同時に消す":
    kind.assign Place
  of "連結で消す":
    kind.assign Connection
  of "累計色消す":
    kind.assign AccumColor
  of "累計個消す":
    kind.assign AccumCount
  else:
    return err errorMsg

  ok Goal.init(kind, color, val, valOperator, clearColorOpt)

# ------------------------------------------------
# Goal <-> URI
# ------------------------------------------------

const
  QuerySep = "_"
  KindToIshikawaUri = "uEGIQac"
  ColorToIshikawaUri = "06712345"
  ValToIshikawaUri = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-"
  ClearIshikawaUri = '2'
  EmptyValIshikawaUri = '0'

func toUriQuery*(self: Goal, fqdn = Pon2): Pon2Result[string] {.inline, noinit.} =
  ## Returns the URI query converted from the requirement.
  case fqdn
  of Pon2:
    let
      mainQuery =
        if self.mainOpt.isOk:
          let main = self.mainOpt.unsafeValue
          [$main.kind.ord, $main.color.ord, $main.val, $main.valOperator.ord].join QuerySep
        else:
          ""
      clearQuery =
        if self.clearColorOpt.isOk:
          $self.clearColorOpt.unsafeValue.ord
        else:
          ""

    ok "{mainQuery}{QuerySep}{clearQuery}".fmt
  of IshikawaPuyo, Ips:
    # check value
    if self.mainOpt.isOk:
      let main = self.mainOpt.unsafeValue

      const ValMax = ValToIshikawaUri.len - 1
      if main.val notin 0 .. ValMax:
        return err "IshikawaPuyo/Ips format only supports the value in [0, {ValMax}], but got {main.val}".fmt

    if self.clearColorOpt.isOk:
      let
        colorChar = ColorToIshikawaUri[self.clearColorOpt.unsafeValue.ord]
        (kindChar, valChar) =
          if self.mainOpt.isOk:
            let main = self.mainOpt.unsafeValue
            if main.kind != Chain:
              return err "IshikawaPuyo/Ips format only supports clearColor alone or with Chain, but got {main.kind}".fmt

            (
              KindToIshikawaUri[main.kind.ord].succ main.valOperator.ord + 2,
              ValToIshikawaUri[main.val],
            )
          else:
            (ClearIshikawaUri, EmptyValIshikawaUri)

      ok "{kindChar}{colorChar}{valChar}".fmt
    else:
      if self.mainOpt.isErr:
        return ok ""
      let main = self.mainOpt.unsafeValue

      let
        kindChar = KindToIshikawaUri[main.kind.ord].succ main.valOperator.ord
        colorChar = ColorToIshikawaUri[main.color.ord]
        valChar = ValToIshikawaUri[main.val]

      ok "{kindChar}{colorChar}{valChar}".fmt

func parseGoal*(
    query: string, fqdn: SimulatorFqdn
): Pon2Result[Goal] {.inline, noinit.} =
  ## Returns the goal converted from the URI query.
  if query == "":
    return ok NoneGoal

  case fqdn
  of Pon2:
    let strs = query.rsplit(QuerySep, 1)
    if strs.len != 2:
      return err "Invalid goal: {query}".fmt

    # clearColor
    var clearColorOpt = Opt[GoalColor].err
    if strs[1] != "":
      clearColorOpt.ok ?parseOrdinal[GoalColor](strs[1]).context "Invalid goal (clearColor): {query}".fmt

    if strs[0] == "":
      return ok Goal.init clearColorOpt

    let mainStrs = strs[0].split QuerySep
    if mainStrs.len != 4:
      return err "Invalid goal: {query}".fmt

    let
      kind =
        ?parseOrdinal[GoalKind](mainStrs[0]).context "Invalid goal (kind): {query}".fmt
      color =
        ?parseOrdinal[GoalColor](mainStrs[1]).context "Invalid goal (color): {query}".fmt
      val = ?mainStrs[2].parseInt.context "Invalid goal (val): {query}".fmt
      valOperator =
        ?parseOrdinal[GoalValOperator](mainStrs[3]).context "Invalid goal (val operator): {query}".fmt

    ok Goal.init(kind, color, val, valOperator, clearColorOpt)
  of IshikawaPuyo, Ips:
    if query.len != 3:
      return err "Invalid goal: {query}".fmt

    # color
    var color = GoalColor.low
    let colorIndex = ColorToIshikawaUri.find query[1]
    if colorIndex >= 0:
      color.assign colorIndex.GoalColor
    else:
      return err "Invalid goal (color): {query}".fmt

    if query[0] == ClearIshikawaUri:
      return ok Goal.init color

    # kind, operator, clear
    var
      kind = GoalKind.low
      valOperator = GoalValOperator.low
      clear = false
    case query[0]
    of KindToIshikawaUri[Chain.ord].succ 2:
      kind.assign Chain
      valOperator.assign Exact
      clear.assign true
    of KindToIshikawaUri[Chain.ord].succ 3:
      kind.assign Chain
      valOperator.assign AtLeast
      clear.assign true
    else:
      let kindIndex = KindToIshikawaUri.find query[0]
      if kindIndex >= 0:
        kind.assign kindIndex.GoalKind
        valOperator.assign Exact
      else:
        let atLeastKindIndex = KindToIshikawaUri.find query[0].pred
        if atLeastKindIndex >= 0:
          kind.assign atLeastKindIndex.GoalKind
          valOperator.assign AtLeast
        else:
          return err "Invalid goal (kind): {query}".fmt

    # val
    let val = ValToIshikawaUri.find query[2]
    if val < 0:
      return err "Invalid goal (val): {query}".fmt

    # clearColor
    var clearColorOpt = NoneGoalColor
    if clear:
      clearColorOpt.ok color
      color.assign GoalColor.low

    ok Goal.init(kind, color, val, valOperator, clearColorOpt)
