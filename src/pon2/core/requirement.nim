## This module implements Nazo Puyo requirements.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[setutils, strutils, sugar, tables, uri]
import ../core/[host]

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

  Requirement* = object
    ## Nazo Puyo requirement to clear.
    ## Note that `Clear` kind has no number, but it is included due to technical
    ## reason in Nim; the value should be zero.
    case kind*: RequirementKind
    of DisappearColor, DisappearColorMore, Chain, ChainMore, DisappearColorSametime,
        DisappearColorMoreSametime:
      discard
    else:
      color*: RequirementColor
    number*: RequirementNumber

const
  NoColorKinds* = {
    DisappearColor, DisappearColorMore, Chain, ChainMore, DisappearColorSametime,
    DisappearColorMoreSametime,
  } ## All requirement kinds not containing 'c'.
  NoNumberKinds* = {Clear} ## All requirement kinds not containing 'n'.

  ColorKinds* = NoColorKinds.complement ## All requirement kinds containing 'c'.
  NumberKinds* = NoNumberKinds.complement ## All requirement kinds containing 'n'.

using
  self: Requirement
  mSelf: var Requirement

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `==`*(self; req: Requirement): bool {.inline.} =
  self.kind == req.kind and self.number == req.number and
    (req.kind notin ColorKinds or self.color == req.color)

# ------------------------------------------------
# Property
# ------------------------------------------------

func isSupported*(self): bool {.inline.} =
  ## Returns `true` if the requirement is supported.
  self.kind notin
    {DisappearPlace, DisappearPlaceMore, DisappearConnect, DisappearConnectMore} or
    self.color != Garbage

# ------------------------------------------------
# Requirement <-> string
# ------------------------------------------------

func `$`*(req: Requirement): string {.inline.} =
  result = ($req.kind).replace("n", $req.number)
  if req.kind in ColorKinds:
    result = result.replace("c", $req.color)

# NOTE: this should be put after `$`
{.cast(uncheckedAssign).}:
  const
    AllRequirementsClear = collect:
      for color in RequirementColor:
        Requirement(kind: Clear, color: color, number: 0)
    AllRequirementsWithColor = collect:
      for kind in ColorKinds - {Clear}:
        for color in RequirementColor:
          for num in RequirementNumber.low .. RequirementNumber.high:
            Requirement(kind: kind, color: color, number: num)
    AllRequirementsWithoutColor = collect:
      for kind in NoColorKinds:
        for num in RequirementNumber.low .. RequirementNumber.high:
          Requirement(kind: kind, number: num)
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

func toUriQuery*(req: Requirement, host: SimulatorHost): string {.inline.} =
  ## Returns the URI query converted from the requirement.
  case host
  of Ik:
    var queries = @[(KindKey, $req.kind.ord)]
    if req.kind in ColorKinds:
      queries.add (ColorKey, $req.color.ord)
    if req.kind in NumberKinds:
      queries.add (NumberKey, $req.number)

    result = queries.encodeQuery
  of Ishikawa, Ips:
    let
      kindChar = KindToIshikawaUri[req.kind.ord]
      colorChar =
        if req.kind in ColorKinds:
          ColorToIshikawaUri[req.color.ord]
        else:
          EmptyIshikawaUri
      numChar =
        if req.kind in NumberKinds:
          NumberToIshikawaUri[req.number]
        else:
          EmptyIshikawaUri

    result = kindChar & colorChar & numChar

func parseRequirement*(query: string, host: SimulatorHost): Requirement {.inline.} =
  ## Returns the requirement converted from the URI query.
  ## If the query is invalid, `ValueError` is raised.
  var
    kind = RequirementKind.low
    color = RequirementColor.low
    number = RequirementNumber.low

  case host
  of Ik:
    var
      kindSet = false
      colorSet = false
      numberSet = false

    for (key, val) in query.decodeQuery:
      case key
      of KindKey:
        let kindInt = val.parseInt
        if kindInt notin RequirementKind.low.ord .. RequirementKind.high.ord:
          raise newException(ValueError, "Invalid requirement: " & query)

        kind = kindInt.RequirementKind
        kindSet = true
      of ColorKey:
        var colorInt = val.parseInt
        if colorInt notin RequirementColor.low.ord .. RequirementColor.high.ord:
          raise newException(ValueError, "Invalid requirement: " & query)

        color = colorInt.RequirementColor
        colorSet = true
      of NumberKey:
        let numberInt = val.parseInt
        if numberInt notin RequirementNumber.low.ord .. RequirementNumber.high.ord:
          raise newException(ValueError, "Invalid requirement: " & query)

        number = numberInt.RequirementNumber
        numberSet = true
      else:
        raise newException(ValueError, "Invalid requirement: " & query)

    if not kindSet or (kind in ColorKinds != colorSet) or
        (kind in NumberKinds != numberSet):
      raise newException(ValueError, "Invalid requirement: " & query)
  of Ishikawa, Ips:
    if query.len != 3 or query[0] notin IshikawaUriToKind or
        query[1] notin IshikawaUriToColor or query[2] notin IshikawaUriToNumber:
      raise newException(ValueError, "Invalid requirement: " & query)

    kind = IshikawaUriToKind[query[0]]
    if kind in ColorKinds:
      color = IshikawaUriToColor[query[1]]
    if kind in NumberKinds:
      number = IshikawaUriToNumber[query[2]]

    if kind == Clear:
      number = RequirementNumber.low

  {.cast(uncheckedAssign).}:
    if kind in ColorKinds:
      result = Requirement(kind: kind, color: color, number: number)
    else:
      result = Requirement(kind: kind, number: number)
