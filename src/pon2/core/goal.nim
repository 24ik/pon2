## This module implements Nazo Puyo goals.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[setutils, strformat, sugar]
import ./[fqdn]
import ../private/[assign, results2, strutils, tables]

export results2

type
  GoalKind* {.pure.} = enum
    ## Kind of the goal to clear the Nazo Puyo.
    None = "クリア条件未設定"
    Chain = "n連鎖するべし"
    Color = "n色同時に消すべし"
    Count = "cぷよn個同時に消すべし"
    Place = "cぷよn箇所同時に消すべし"
    Connection = "cぷよn連結で消すべし"
    AccumColor = "n色消すべし"
    AccumCount = "cぷよn個消すべし"

  GoalColor* {.pure.} = enum
    ## 'c' in the `GoalKind`.
    None = "クリア条件色未設定"
    All = ""
    Red = "赤"
    Green = "緑"
    Blue = "青"
    Yellow = "黄"
    Purple = "紫"
    Garbages = "おじゃま"
    Colors = "色"

  GoalValOperator* {.pure.} = enum
    ## Operator used in comparison of the value.
    Exact = "ちょうど"
    AtLeast = "以上"

  Goal* = object ## Nazo Puyo goal to clear.
    kind*: GoalKind
    color*: GoalColor
    val*: int
    valOperator*: GoalValOperator
    clearColor*: GoalColor

const
  ColorKinds* = {Count, Place, Connection, AccumCount} ## All goal kinds containing 'c'.
  NoColorKinds* = ColorKinds.complement ## All goal kinds not containing 'c'.

  DefaultKind = GoalKind.None
  DefaultColor = GoalColor.None
  DefaultVal = 0
  DefaultValOperator = Exact
  DefaultClearColor = GoalColor.None

  NoneGoal* = Goal(
    kind: GoalKind.None,
    color: DefaultColor,
    val: DefaultVal,
    valOperator: DefaultValOperator,
    clearColor: GoalColor.None,
  )

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(
    T: type Goal,
    kind: GoalKind,
    color: GoalColor,
    val: int,
    valOperator: GoalValOperator,
    clearColor: GoalColor,
): T {.inline, noinit.} =
  T(
    kind: kind, color: color, val: val, valOperator: valOperator, clearColor: clearColor
  )

func init*(
    T: type Goal,
    kind: GoalKind,
    color: GoalColor,
    val: int,
    valOperator: GoalValOperator,
): T {.inline, noinit.} =
  T.init(kind, color, val, valOperator, DefaultClearColor)

func init*(
    T: type Goal,
    kind: GoalKind,
    val: int,
    valOperator: GoalValOperator,
    clearColor: GoalColor,
): T {.inline, noinit.} =
  T.init(kind, DefaultColor, val, valOperator, clearColor)

func init*(
    T: type Goal, kind: GoalKind, val: int, valOperator: GoalValOperator
): T {.inline, noinit.} =
  T.init(kind, DefaultColor, val, valOperator, DefaultClearColor)

func init*(T: type Goal, clearColor: GoalColor): T {.inline, noinit.} =
  T.init(DefaultKind, DefaultColor, DefaultVal, DefaultValOperator, clearColor)

func init*(T: type Goal): T {.inline, noinit.} =
  NoneGoal

# ------------------------------------------------
# Property
# ------------------------------------------------

func isSupported*(self: Goal): bool {.inline, noinit.} =
  ## Returns `true` if the goal is supported.
  case self.kind
  of GoalKind.None:
    self.clearColor != GoalColor.None
  of ColorKinds:
    self.color != GoalColor.None and
      not (self.kind in {Place, Connection} and self.color == Garbages)
  else:
    true

# ------------------------------------------------
# Normalize
# ------------------------------------------------

func isNormalized*(self: Goal): bool {.inline, noinit.} =
  ## Returns `true` if the goal is normalized.
  case self.kind
  of GoalKind.None:
    self.color == DefaultColor and self.val == DefaultVal and
      self.valOperator == DefaultValOperator
  else:
    not (self.kind notin ColorKinds and self.color != DefaultColor)

func normalize*(self: var Goal) {.inline, noinit.} =
  ## Normalizes the goal.
  if self.kind in NoColorKinds:
    self.color.assign DefaultColor

    if self.kind == GoalKind.None:
      self.val.assign DefaultVal
      self.valOperator.assign DefaultValOperator

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
  AtleastPlaceholder = "<ATLEAST>"
  ExactStr = "ちょうど"
  AtLeastStr = "以上"

  GoalKindStrs: array[GoalKind, string] = [
    $GoalKind.None, "{ExactPlaceholder}n連鎖{AtLeastPlaceholder}する".fmt,
    "{ExactPlaceholder}n色{AtLeastPlaceholder}同時に消す".fmt,
    "cぷよ{ExactPlaceholder}n個{AtLeastPlaceholder}同時に消す".fmt,
    "cぷよ{ExactPlaceholder}n箇所{AtLeastPlaceholder}で同時に消す".fmt,
    "cぷよ{ExactPlaceholder}n連結{AtLeastPlaceholder}で消す".fmt,
    "累計{ExactPlaceholder}n色{AtLeastPlaceholder}消す".fmt,
    "cぷよ累計{ExactPlaceholder}n個{AtLeastPlaceholder}消す".fmt,
  ]
  ClearStr = "cぷよ全て消す"

func `$`*(self: Goal): string {.inline, noinit.} =
  if self == NoneGoal:
    return $GoalKind.None

  let
    kindStr =
      case self.kind
      of GoalKind.None:
        ""
      else:
        var replacer = @[("c", $self.color), ("n", $self.val)]
        case self.valOperator
        of Exact:
          replacer.add (ExactPlaceholder, ExactStr)
          replacer.add (AtLeastPlaceholder, "")
        of AtLeast:
          replacer.add (ExactPlaceholder, "")
          replacer.add (AtLeastPlaceholder, AtLeastStr)

        GoalKindStrs[self.kind].multiReplace replacer
    clearStr =
      case self.clearColor
      of GoalColor.None:
        ""
      else:
        ClearStr.replace("c", $self.clearColor)

  "{kindStr}{GoalSep}{clearStr}".fmt.strip(chars = {GoalSep}) & GoalSuffix

func parseGoal*(str: string): StrErrorResult[Goal] {.inline, noinit.} =
  ## Returns the goal converted from the string representation.
  let errorMsg = "Invalid goal: {str}".fmt

  # none goal
  if str in ["", $GoalKind.None]:
    return ok NoneGoal

  if not str.endsWith GoalSuffix:
    return err errorMsg

  let strs = str.replace(GoalSuffix, "").split GoalSep
  if strs.len > 2:
    return err errorMsg

  # clearColor
  var clearColor = GoalColor.None
  for color in GoalColor:
    if color == GoalColor.None:
      continue

    let clearStr = ClearStr.replace("c", $color)

    if strs.len == 1 and strs[0] == clearStr:
      return ok Goal.init color

    if clearStr in strs:
      clearColor.assign color
      break

  # operator
  var
    valOperator = DefaultValOperator
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
  var
    valOpt = Opt[int].err
    kindStrNoVal = kindStr
  for charIndex, c in kindStr:
    if not (
      c.isDigit or
      (c == '-' and charIndex.succ < kindStr.len and kindStr[charIndex.succ].isDigit)
    ):
      continue

    var endIndex = charIndex.succ
    while endIndex < kindStr.len and kindStr[endIndex].isDigit:
      endIndex.inc

    let valStr = kindStr[charIndex ..< endIndex]
    valOpt.ok ?valStr.parseInt.context errorMsg
    kindStrNoVal.assign kindStr.replace(valStr, "")
    break
  if valOpt.isErr:
    return err errorMsg

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
  var kind = DefaultKind
  case kindStrNoValColor
  of "連鎖する":
    kind.assign Chain
  of "色同時に消す":
    kind.assign Color
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

  ok Goal.init(kind, color, valOpt.unsafeValue, valOperator, clearColor)

# ------------------------------------------------
# Goal <-> URI
# ------------------------------------------------

const
  QuerySep = "_"
  KindToIshikawaUri = "2uEGIQac"
  ColorToIshikawaUri = "001234567"
  ValToIshikawaUri = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-"

func toUriQuery*(self: Goal, fqdn = Pon2): StrErrorResult[string] {.inline, noinit.} =
  ## Returns the URI query converted from the requirement.
  case fqdn
  of Pon2:
    ok [
      $self.kind.ord,
      $self.color.ord,
      $self.val,
      $self.valOperator.ord,
      $self.clearColor.ord,
    ].join QuerySep
  of Ishikawa, Ips:
    if self.kind == GoalKind.None and self.clearColor == GoalColor.None:
      return ok ""
    if self.val notin 0 ..< ValToIshikawaUri.len:
      return err "Ishikawa/Ips format only supports the value in [0, {ValToIshikawaUri.len.pred}], but got {self.val}".fmt
    if self.clearColor != GoalColor.None and self.kind notin {GoalKind.None, Chain}:
      return err "Ishikawa/Ips format only supports clearColor alone or with Chain, but got {self.kind}".fmt

    let
      # kind
      kindChar = KindToIshikawaUri[self.kind.ord].succ(
        if self.kind == Chain and self.clearColor != GoalColor.None: 2 else: 0
      ).succ (self.valOperator == AtLeast).int

      # color
      color = if self.kind in {GoalKind.None, Chain}: self.clearColor else: self.color
      colorChar = ColorToIshikawaUri[color.ord]

      # val
      valChar = ValToIshikawaUri[self.val]

    ok "{kindChar}{colorChar}{valChar}".fmt

func parseGoal*(
    query: string, fqdn: SimulatorFqdn
): StrErrorResult[Goal] {.inline, noinit.} =
  ## Returns the goal converted from the URI query.
  if query == "":
    return ok NoneGoal

  case fqdn
  of Pon2:
    let strs = query.split QuerySep
    if strs.len != 5:
      return err "Invalid goal: {query}".fmt

    # kind
    var kind = DefaultKind
    let
      kindErrorMsg = "Invalid goal (kind): {query}".fmt
      kindOrd = ?strs[0].parseInt.context kindErrorMsg
    if kindOrd in GoalKind.low.ord .. GoalKind.high.ord:
      kind.assign kindOrd.GoalKind
    else:
      return err kindErrorMsg

    # color
    var color = DefaultColor
    let
      colorErrorMsg = "Invalid goal (color): {query}".fmt
      colorOrd = ?strs[1].parseInt.context colorErrorMsg
    if colorOrd in GoalColor.low.ord .. GoalColor.high.ord:
      color.assign colorOrd.GoalColor
    else:
      return err colorErrorMsg

    # val
    let val = ?strs[2].parseInt.context "Invalid goal (val): {query}".fmt

    # operator
    var valOperator = DefaultValOperator
    let
      valOperatorErrorMsg = "Invalid goal (val operator): {query}".fmt
      valOperatorOrd = ?strs[3].parseInt.context valOperatorErrorMsg
    if valOperatorOrd in GoalValOperator.low.ord .. GoalValOperator.high.ord:
      valOperator.assign valOperatorOrd.GoalValOperator
    else:
      return err valOperatorErrorMsg

    # clearColor
    var clearColor = GoalColor.None
    let
      clearColorErrorMsg = "Invalid goal (clearColor): {query}".fmt
      clearColorOrd = ?strs[4].parseInt.context clearColorErrorMsg
    if clearColorOrd in GoalColor.low.ord .. GoalColor.high.ord:
      clearColor.assign clearColorOrd.GoalColor
    else:
      return err clearColorErrorMsg

    ok Goal.init(kind, color, val, valOperator, clearColor)
  of Ishikawa, Ips:
    if query.len != 3:
      return err "Invalid goal: {query}".fmt

    # kind, operator, clear
    var
      kind = DefaultKind
      valOperator = DefaultValOperator
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
      let
        kindErrorMsg = "Invalid goal (kind): {query}".fmt
        kindIndex = KindToIshikawaUri.find query[0]
      if kindIndex >= 0:
        kind.assign kindIndex.GoalKind
        valOperator.assign Exact

        if kindIndex == GoalColor.None.ord:
          clear.assign true
      else:
        let atLeastKindIndex = KindToIshikawaUri.find query[0].pred
        if atLeastKindIndex >= 0:
          kind.assign atLeastKindIndex.GoalKind
          valOperator.assign AtLeast
        else:
          return err kindErrorMsg

    # color
    var color = DefaultColor
    let colorIndex = ColorToIshikawaUri.find query[1]
    if colorIndex >= 0:
      color.assign colorIndex.GoalColor
    else:
      return err "Invalid goal (color): {query}".fmt
    if (kind in ColorKinds or clear) and color == GoalColor.None:
      color.assign All

    # val
    var val = DefaultVal
    let valIndex = ValToIshikawaUri.find query[2]
    if valIndex >= 0:
      val.assign valIndex
    else:
      return err "Invalid goal (val): {query}".fmt

    # clearColor
    var clearColor = GoalColor.None
    if clear:
      clearColor.assign color
      color.assign DefaultColor

    ok Goal.init(kind, color, val, valOperator, clearColor)
