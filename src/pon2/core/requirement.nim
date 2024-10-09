## This module implements Nazo Puyo requirements.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[options, setutils, strutils, sugar, tables, uri]
import ../core/[fqdn]

type
  RequirementKind* {.pure.} = enum
    ## Kind of the requirement to clear the nazo puyo.
    Clear = "cぷよ全て消すべし"
    DisappearColor = "n色消すべし"
    DisappearColorMore = "n色以上消すべし"
    DisappearCount = "cぷよn個消すべし"
    DisappearCountMore = "cぷよn個以上消すべし"
    Chain = "n連鎖するべし"
    ChainMore = "n連鎖以上するべし"
    ChainClear = "n連鎖&cぷよ全て消すべし"
    ChainMoreClear = "n連鎖以上&cぷよ全て消すべし"
    DisappearColorSametime = "n色同時に消すべし"
    DisappearColorMoreSametime = "n色以上同時に消すべし"
    DisappearCountSametime = "cぷよn個同時に消すべし"
    DisappearCountMoreSametime = "cぷよn個以上同時に消すべし"
    DisappearPlace = "cぷよn箇所同時に消すべし"
    DisappearPlaceMore = "cぷよn箇所以上同時に消すべし"
    DisappearConnect = "cぷよn連結で消すべし"
    DisappearConnectMore = "cぷよn連結以上で消すべし"

  RequirementColor* {.pure.} = enum
    ## 'c' in the `RequirementKind`.
    All = ""
    Red = "赤"
    Green = "緑"
    Blue = "青"
    Yellow = "黄"
    Purple = "紫"
    Garbage = "おじゃま"
    Color = "色"

  RequirementNumber* = range[0 .. 63] ## 'n' in the `RequirementKind`.

  Requirement* = object ## Nazo Puyo requirement to clear.
    kind: RequirementKind
    color: Option[RequirementColor]
    number: Option[RequirementNumber]

const
  NoColorKinds* = {
    DisappearColor, DisappearColorMore, Chain, ChainMore, DisappearColorSametime,
    DisappearColorMoreSametime,
  } ## All requirement kinds not containing 'c'.
  NoNumberKinds* = {Clear} ## All requirement kinds not containing 'n'.

  ColorKinds* = NoColorKinds.complement ## All requirement kinds containing 'c'.
  NumberKinds* = NoNumberKinds.complement ## All requirement kinds containing 'n'.

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func initRequirement*(
    kind: RequirementKind, color: RequirementColor, number: RequirementNumber
): Requirement {.inline.} =
  ## Returns a requirement.
  Requirement(kind: kind, color: some color, number: some number)

func initRequirement*(
    kind: RequirementKind, color: RequirementColor
): Requirement {.inline.} =
  ## Returns a requirement.
  Requirement(kind: kind, color: some color, number: none RequirementNumber)

func initRequirement*(
    kind: RequirementKind, number: RequirementNumber
): Requirement {.inline.} =
  Requirement(kind: kind, color: none RequirementColor, number: some number)

# ------------------------------------------------
# Property
# ------------------------------------------------

const
  DefaultColor = All
  DefaultNumber = 0.RequirementNumber

func isSupported*(self: Requirement): bool {.inline.} =
  ## Returns `true` if the requirement is supported.
  self.kind notin
    {DisappearPlace, DisappearPlaceMore, DisappearConnect, DisappearConnectMore} or
    self.color != some Garbage

func kind*(self: Requirement): RequirementKind {.inline.} =
  ## Returns the kind of the requirement.
  self.kind

func color*(self: Requirement): RequirementColor {.inline.} =
  ## Returns the color of the requirement.
  ## If the requirement does not have a color, `UnpackDefect` is raised.
  self.color.get

func number*(self: Requirement): RequirementNumber {.inline.} =
  ## Returns the number of the requirement.
  ## If the requirement does not have a number, `UnpackDefect` is raised.
  self.number.get

func `kind=`*(self: var Requirement, kind: RequirementKind) {.inline.} =
  ## Sets the kind of the requirement.
  if self.kind == kind:
    return
  self.kind = kind

  if kind in ColorKinds:
    if self.color.isNone:
      self.color = some DefaultColor
  else:
    if self.color.isSome:
      self.color = none RequirementColor

  if kind in NumberKinds:
    if self.number.isNone:
      self.number = some DefaultNumber
  else:
    if self.number.isSome:
      self.number = none RequirementNumber

func `color=`*(self: var Requirement, color: RequirementColor) {.inline.} =
  ## Sets the color of the requirement.
  ## If the requirement does not have a color, `UnpackDefect` is raised.
  if self.kind in NoColorKinds:
    raise newException(UnpackDefect, "The requirement does not have a color.")

  self.color = some color

func `number=`*(self: var Requirement, number: RequirementNumber) {.inline.} =
  ## Sets the number of the requirement.
  ## If the requirement does not have a color, `UnpackDefect` is raised.
  if self.kind in NoNumberKinds:
    raise newException(UnpackDefect, "The requirement does not have a number.")

  self.number = some number

# ------------------------------------------------
# Requirement <-> string
# ------------------------------------------------

func `$`*(self: Requirement): string {.inline.} =
  result = $self.kind
  if self.kind in ColorKinds:
    result = result.replace("c", $self.color.get)
  if self.kind in NumberKinds:
    result = result.replace("n", $self.number.get)

# NOTE: this should be put after `$`
{.cast(uncheckedAssign).}:
  const
    AllRequirementsClear = collect:
      for color in RequirementColor:
        initRequirement(Clear, color)
    AllRequirementsWithColor = collect:
      for kind in ColorKinds - {Clear}:
        for color in RequirementColor:
          for num in RequirementNumber.low .. RequirementNumber.high:
            initRequirement(kind, color, num)
    AllRequirementsWithoutColor = collect:
      for kind in NoColorKinds:
        for num in RequirementNumber.low .. RequirementNumber.high:
          initRequirement(kind, num)
const StrToRequirement = collect:
  for req in AllRequirementsClear & AllRequirementsWithColor &
      AllRequirementsWithoutColor:
    {$req: req}

func parseRequirement*(str: string): Requirement {.inline.} =
  ## Returns the requirement converted from the string representation.
  ## If the string is invalid, `ValueError` is raised.
  if str notin StrToRequirement:
    raise newException(ValueError, "Invalid requirement: " & str)

  result = StrToRequirement[str]

# ------------------------------------------------
# Requirement <-> URI
# ------------------------------------------------

const
  KindToIshikawaUri = "2abcduvwxEFGHIJQR"
  ColorToIshikawaUri = "01234567"
  NumberToIshikawaUri =
    "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-"
  EmptyIshikawaUri = '0'

  IshikawaUriToKind = collect:
    for i, uri in KindToIshikawaUri:
      {uri: i.RequirementKind}
  IshikawaUriToColor = collect:
    for i, uri in ColorToIshikawaUri:
      {uri: i.RequirementColor}
  IshikawaUriToNumber = collect:
    for i, uri in NumberToIshikawaUri:
      {uri: i.RequirementNumber}

  KindKey = "req-kind"
  ColorKey = "req-color"
  NumberKey = "req-number"

  RequirementQueryKeys* = [KindKey, ColorKey, NumberKey]

func toUriQuery*(self: Requirement, fqdn = Pon2): string {.inline.} =
  ## Returns the URI query converted from the requirement.
  case fqdn
  of Pon2:
    var queries = @[(KindKey, $self.kind.ord)]
    if self.kind in ColorKinds:
      queries.add (ColorKey, $self.color.get.ord)
    if self.kind in NumberKinds:
      queries.add (NumberKey, $self.number.get)

    result = queries.encodeQuery
  of Ishikawa, Ips:
    let
      kindChar = KindToIshikawaUri[self.kind.ord]
      colorChar =
        if self.kind in ColorKinds:
          ColorToIshikawaUri[self.color.get.ord]
        else:
          EmptyIshikawaUri
      numChar =
        if self.kind in NumberKinds:
          NumberToIshikawaUri[self.number.get]
        else:
          EmptyIshikawaUri

    result = kindChar & colorChar & numChar

func parseRequirement*(query: string, fqdn: IdeFqdn): Requirement {.inline.} =
  ## Returns the requirement converted from the URI query.
  ## If the query is invalid, `ValueError` is raised.
  result = Requirement(
    kind: RequirementKind.low,
    color: none RequirementColor,
    number: none RequirementNumber,
  )

  case fqdn
  of Pon2:
    var kindSet = false
    for (key, val) in query.decodeQuery:
      case key
      of KindKey:
        if kindSet:
          raise newException(ValueError, "Invalid requirement: " & query)

        let kindInt = val.parseInt
        if kindInt notin RequirementKind.low.ord .. RequirementKind.high.ord:
          raise newException(ValueError, "Invalid requirement: " & query)

        result.kind = kindInt.RequirementKind
        kindSet = true
      of ColorKey:
        if result.color.isSome:
          raise newException(ValueError, "Invalid requirement: " & query)

        let colorInt = val.parseInt
        if colorInt notin RequirementColor.low.ord .. RequirementColor.high.ord:
          raise newException(ValueError, "Invalid requirement: " & query)

        result.color = some colorInt.RequirementColor
      of NumberKey:
        if result.number.isSome:
          raise newException(ValueError, "Invalid requirement: " & query)

        let numberInt = val.parseInt
        if numberInt notin RequirementNumber.low.ord .. RequirementNumber.high.ord:
          raise newException(ValueError, "Invalid requirement: " & query)

        result.number = some numberInt.RequirementNumber
      else:
        raise newException(ValueError, "Invalid requirement: " & query)

    if not kindSet or (result.kind in ColorKinds != result.color.isSome) or
        (result.kind in NumberKinds != result.number.isSome):
      raise newException(ValueError, "Invalid requirement: " & query)
  of Ishikawa, Ips:
    if query.len != 3 or query[0] notin IshikawaUriToKind or
        query[1] notin IshikawaUriToColor or query[2] notin IshikawaUriToNumber:
      raise newException(ValueError, "Invalid requirement: " & query)

    result.kind = IshikawaUriToKind[query[0]]
    if result.kind in ColorKinds:
      result.color = some IshikawaUriToColor[query[1]]
    if result.kind in NumberKinds:
      result.number = some IshikawaUriToNumber[query[2]]
