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
    ## Kind of the goal to clear the nazo puyo.
    Chain = "n連鎖するべし"
    Color = "n色同時に消すべし"
    Count = "cぷよn個同時に消すべし"
    Place = "cぷよn箇所同時に消すべし"
    Connection = "cぷよn連結で消すべし"
    AccumColor = "n色消すべし"
    AccumCount = "cぷよn個消すべし"

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

  Goal* = object ## Nazo Puyo goal to clear.
    kindOpt*: Opt[GoalKind]
    color*: GoalColor
    val*: int
    exact*: bool
    clearColorOpt*: Opt[GoalColor]

const
  NoColorKinds* = {AccumColor, Chain, Color} ## All goal kinds not containing 'c'.
  ColorKinds* = NoColorKinds.complement ## All goal kinds containing 'c'.

  DefaultKindOpt = Opt[GoalKind].err
  DefaultColor = GoalColor.low
  DefaultVal = 0
  DefaultExact = true
  DefaultClearColorOpt = Opt[GoalColor].err

  NoneGoal* = Goal(
    kindOpt: DefaultKindOpt,
    color: DefaultColor,
    val: DefaultVal,
    exact: DefaultExact,
    clearColorOpt: DefaultClearColorOpt,
  )

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init(
    T: type Goal,
    kindOpt = DefaultKindOpt,
    color = DefaultColor,
    val = DefaultVal,
    exact = DefaultExact,
    clearColorOpt = DefaultClearColorOpt,
): T {.inline, noinit.} =
  T(
    kindOpt: kindOpt, color: color, val: val, exact: exact, clearColorOpt: clearColorOpt
  )

func init*(
    T: type Goal,
    kind: GoalKind,
    color: GoalColor,
    val: int,
    exact: bool,
    clearColor: GoalColor,
): T {.inline, noinit.} =
  T.init(Opt[GoalKind].ok kind, color, val, exact, Opt[GoalColor].ok clearColor)

func init*(
    T: type Goal, kind: GoalKind, color: GoalColor, val: int, exact: bool
): T {.inline, noinit.} =
  T.init(Opt[GoalKind].ok kind, color, val, exact)

func init*(
    T: type Goal, kind: GoalKind, val: int, exact: bool, clearColor: GoalColor
): T {.inline, noinit.} =
  T.init(
    Opt[GoalKind].ok kind,
    val = val,
    exact = exact,
    clearColorOpt = Opt[GoalColor].ok clearColor,
  )

func init*(T: type Goal, kind: GoalKind, val: int, exact: bool): T {.inline, noinit.} =
  T.init(Opt[GoalKind].ok kind, val = val, exact = exact)

func init*(T: type Goal, clearColor: GoalColor): T {.inline, noinit.} =
  T.init(clearColorOpt = Opt[GoalColor].ok clearColor)

func init*(T: type Goal): T {.inline, noinit.} =
  NoneGoal

# ------------------------------------------------
# Property
# ------------------------------------------------

func isSupported*(self: Goal): bool {.inline, noinit.} =
  ## Returns `true` if the goal is supported.
  if self.kindOpt.isOk:
    not (self.kindOpt.unsafeValue in {Place, Connection} and self.color == Garbages)
  else:
    self.clearColorOpt.isOk

# ------------------------------------------------
# Normalize
# ------------------------------------------------

func isNormalized*(self: Goal): bool {.inline, noinit.} =
  ## Returns `true` if the goal is normal form.
  if self.kindOpt.isOk:
    if self.kindOpt.unsafeValue in ColorKinds:
      true
    else:
      self.color == DefaultColor
  else:
    self.color == DefaultColor and self.val == DefaultVal and self.exact == DefaultExact

func normalize*(self: var Goal) {.inline, noinit.} =
  ## Normalizes the goal.
  if self.kindOpt.isOk:
    if self.kindOpt.unsafeValue in NoColorKinds:
      self.color.assign DefaultColor
  else:
    self.color.assign DefaultColor
    self.val.assign DefaultVal
    self.exact.assign DefaultExact

func normalized*(self: Goal): Goal {.inline, noinit.} =
  ## Returns the normalized goal.
  self.dup normalize

# ------------------------------------------------
# Goal <-> string
# ------------------------------------------------

const
  GoalSuffix = "べし"

  ExactPlaceholder = "<EXACT>"
  MorePlaceholder = "<MORE>"
  ExactStr = "ちょうど"
  MoreStr = "以上"

  GoalKindStrs: array[GoalKind, string] = [
    "{ExactPlaceholder}n連鎖{MorePlaceholder}する".fmt,
    "{ExactPlaceholder}n色{MorePlaceholder}同時に消す".fmt,
    "cぷよ{ExactPlaceholder}n個{MorePlaceholder}同時に消す".fmt,
    "cぷよ{ExactPlaceholder}n箇所{MorePlaceholder}で同時に消す".fmt,
    "cぷよ{ExactPlaceholder}n連結{MorePlaceholder}で消す".fmt,
    "累計{ExactPlaceholder}n色{MorePlaceholder}消す".fmt,
    "cぷよ累計{ExactPlaceholder}n個{MorePlaceholder}消す".fmt,
  ]
  ClearStr = "cぷよ全て消す"

  NoneGoalStr = "クリア条件未設定"

func `$`*(self: Goal): string {.inline, noinit.} =
  if self == NoneGoal:
    return NoneGoalStr

  let
    kindStr =
      if self.kindOpt.isOk:
        var replacer = @[("c", $self.color), ("n", $self.val)]
        if self.exact:
          replacer.add (ExactPlaceholder, ExactStr)
          replacer.add (MorePlaceholder, "")
        else:
          replacer.add (ExactPlaceholder, "")
          replacer.add (MorePlaceholder, MoreStr)

        GoalKindStrs[self.kindOpt.unsafeValue].multiReplace replacer
      else:
        ""
    clearStr =
      if self.clearColorOpt.isOk:
        ClearStr.replace("c", $self.clearColorOpt.unsafeValue)
      else:
        ""

  "{kindStr}&{clearStr}".fmt.strip(chars = {'&'}) & GoalSuffix

func parseGoal*(str: string): StrErrorResult[Goal] {.inline, noinit.} =
  ## Returns the goal converted from the string representation.
  let errorMsg = "Invalid goal: {str}".fmt

  # none goal
  if str in ["", NoneGoalStr]:
    return ok NoneGoal

  if not str.endsWith GoalSuffix:
    return err errorMsg

  let strs = str.replace(GoalSuffix, "").split '&'
  if strs.len > 2:
    return err errorMsg

  # clearColor
  var clearColorOpt = Opt[GoalColor].err
  for color in GoalColor:
    let clearStr = ClearStr.replace("c", $color)

    if strs.len == 1 and strs[0] == clearStr:
      return ok Goal.init color

    if clearStr in strs:
      clearColorOpt.ok color
      break

  # exact/more
  var
    exact = true
    kindStr = strs[0]
  if ExactStr in strs[0]:
    exact.assign true
    kindStr.assign strs[0].replace(ExactStr, "")
  elif MoreStr in strs[0]:
    exact.assign false
    kindStr.assign strs[0].replace(MoreStr, "")
  else:
    return err errorMsg

  # value
  var
    valueOpt = Opt[int].err
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
    valueOpt.ok ?valStr.parseInt.context errorMsg
    kindStrNoVal.assign kindStr.replace(valStr, "")
    break
  if valueOpt.isErr:
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
  var kindOpt = Opt[GoalKind].err
  case kindStrNoValColor
  of "連鎖する":
    kindOpt.ok Chain
  of "色同時に消す":
    kindOpt.ok Color
  of "個同時に消す":
    kindOpt.ok Count
  of "箇所で同時に消す":
    kindOpt.ok Place
  of "連結で消す":
    kindOpt.ok Connection
  of "累計色消す":
    kindOpt.ok AccumColor
  of "累計個消す":
    kindOpt.ok AccumCount
  else:
    return err errorMsg

  ok Goal.init(kindOpt, color, valueOpt.unsafeValue, exact, clearColorOpt)

# ------------------------------------------------
# Goal <-> URI
# ------------------------------------------------

const
  QuerySep = "_"
  KindToIshikawaUri = "uEGIQac"
  ClearKindIshikawaUri = '2'
  ColorToIshikawaUri = "01234567"
  EmptyColorIshikawaUri = '0'
  ValToIshikawaUri = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-"

func toUriQuery*(self: Goal, fqdn = Pon2): StrErrorResult[string] {.inline, noinit.} =
  ## Returns the URI query converted from the requirement.
  case fqdn
  of Pon2:
    let queries = [
      if self.kindOpt.isOk:
        $self.kindOpt.unsafeValue.ord
      else:
        "",
      $self.color.ord,
      $self.val,
      $self.exact.int,
      if self.clearColorOpt.isOk:
        $self.clearColorOpt.unsafeValue.ord
      else:
        "",
    ]
    ok queries.join QuerySep
  of Ishikawa, Ips:
    if self == NoneGoal:
      return ok ""
    if self.val notin 0 ..< ValToIshikawaUri.len:
      return err "Ishikawa/Ips format only supports the value in [0, {ValToIshikawaUri.len.pred}], but got {self.val}".fmt
    if self.clearColorOpt.isOk and self.kindOpt.isOk and
        self.kindOpt.unsafeValue != Chain:
      return err "Ishikawa/Ips format does not support clearColor with non-Chain kinds"

    let
      # kind
      kindChar =
        if self.kindOpt.isErr:
          ClearKindIshikawaUri
        else:
          let kind = self.kindOpt.unsafeValue

          KindToIshikawaUri[kind.ord].succ(
            if kind == Chain and self.clearColorOpt.isOk: 2 else: 0
          ).succ (not self.exact).int

      # color
      colorOpt =
        if self.kindOpt.isErr or self.kindOpt.unsafeValue == Chain:
          self.clearColorOpt
        else:
          Opt[GoalColor].ok self.color
      colorChar =
        if colorOpt.isOk:
          ColorToIshikawaUri[colorOpt.unsafeValue.ord]
        else:
          EmptyColorIshikawaUri

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
    var kindOpt = Opt[GoalKind].err
    let kindErrorMsg = "Invalid goal (kind): {query}".fmt
    if strs[0] != "":
      let kindOrd = ?strs[0].parseInt.context kindErrorMsg
      if kindOrd in GoalKind.low.ord .. GoalKind.high.ord:
        kindOpt.ok kindOrd.GoalKind
      else:
        return err kindErrorMsg

    # color
    var color = GoalColor.low
    let
      colorErrorMsg = "Invalid goal (color): {query}".fmt
      colorOrd = ?strs[1].parseInt.context colorErrorMsg
    if colorOrd in GoalColor.low.ord .. GoalColor.high.ord:
      color.assign colorOrd.GoalColor
    else:
      return err colorErrorMsg

    # val
    let val = ?strs[2].parseInt.context "Invalid goal (val): {query}".fmt

    # exact
    var exact = true
    case strs[3]
    of "0":
      exact.assign false
    of "1":
      discard
    else:
      return err "Invalid goal (exact): {query}".fmt

    # clearColor
    var clearColorOpt = Opt[GoalColor].err
    let clearColorErrorMsg = "Invalid goal (clearColor): {query}".fmt
    if strs[4] != "":
      let clearColorOrd = ?strs[4].parseInt.context clearColorErrorMsg
      if clearColorOrd in GoalColor.low.ord .. GoalColor.high.ord:
        clearColorOpt.ok clearColorOrd.GoalColor
      else:
        return err clearColorErrorMsg

    ok Goal.init(kindOpt, color, val, exact, clearColorOpt)
  of Ishikawa, Ips:
    if query.len != 3:
      return err "Invalid goal: {query}".fmt

    # kind, exact
    var
      kindOpt = Opt[GoalKind].err
      exact = true
      clear = false
    let kindErrorMsg = "Invalid goal (kind): {query}".fmt
    case query[0]
    of ClearKindIshikawaUri:
      clear.assign true
    of KindToIshikawaUri[Chain.ord].succ 2:
      kindOpt.ok Chain
      clear.assign true
    of KindToIshikawaUri[Chain.ord].succ 3:
      kindOpt.ok Chain
      clear.assign true
      exact.assign false
    else:
      let kindIndex = KindToIshikawaUri.find query[0]
      if kindIndex >= 0:
        kindOpt.ok kindIndex.GoalKind
      else:
        let moreKindIndex = KindToIshikawaUri.find query[0].pred
        if moreKindIndex >= 0:
          kindOpt.ok moreKindIndex.GoalKind
          exact.assign false
        else:
          return err kindErrorMsg

    # color
    var color = GoalColor.low
    let colorIndex = ColorToIshikawaUri.find query[1]
    if colorIndex >= 0:
      color.assign colorIndex.GoalColor
    else:
      return err "Invalid goal (color): {query}".fmt

    # val
    var val = int.low
    let valIndex = ValToIshikawaUri.find query[2]
    if valIndex >= 0:
      val.assign valIndex
    else:
      return err "Invalid goal (val): {query}".fmt

    # clearColor
    var clearColorOpt = Opt[GoalColor].err
    if clear:
      clearColorOpt.ok color
      color.assign GoalColor.low

    ok Goal.init(kindOpt, color, val, exact, clearColorOpt)
