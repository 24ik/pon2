## This module implements nazo puyos.
##

{.experimental: "strictDefs".}

import std/[options, setutils, strutils, sugar, tables, uri]
import ../corepkg/[environment, field, misc, position]

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

  RequirementNumber* = range[0..63] ## 'n' in the `RequirementKind`.

  Requirement* = object
    ## Nazo Puyo requirement to clear.
    kind*: RequirementKind
    color*: Option[RequirementColor]
    number*: Option[RequirementNumber]

  NazoPuyo*[F: TsuField or WaterField] = object
    ## Nazo Puyo.
    environment*: Environment[F]
    requirement*: Requirement

  NazoPuyos* = object
    ## Nazo puyo type that accepts all rules.
    rule*: Rule
    tsu*: NazoPuyo[TsuField]
    water*: NazoPuyo[WaterField]

const
  NoColorKinds* = {DisappearColor, DisappearColorMore, Chain, ChainMore,
                   DisappearColorSametime, DisappearColorMoreSametime}
    ## All requirement kinds not containing 'c'.
  NoNumberKinds* = {Clear} ## All requirement kinds not containing 'n'.

  ColorKinds* = NoColorKinds.complement ## All requirement kinds containing 'c'.
  NumberKinds* = NoNumberKinds.complement
    ## All requirement kinds containing 'n'.

using
  self: NazoPuyo
  mSelf: var NazoPuyo

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func initNazoPuyo*[F: TsuField or WaterField]: NazoPuyo[F] {.inline.} =
  ## Returns the initial nazo puyo.
  result.environment = initEnvironment[F](0, colorCount = 5, setPairs = false)
  {.push warning[ProveInit]:off.}
  result.requirement = Requirement(
    kind: RequirementKind.low, color: some RequirementColor.All,
    number: none RequirementNumber)
  {.pop.}

func initTsuNazoPuyo*: NazoPuyo[TsuField] {.inline.} = initNazoPuyo[TsuField]()
  ## Returns the initial Tsu nazo puyo.

func initWaterNazoPuyo*: NazoPuyo[WaterField] {.inline.} =
  ## Returns the initial Water nazo puyo.
  initNazoPuyo[WaterField]()

# ------------------------------------------------
# Convert
# ------------------------------------------------

func toTsuNazoPuyo*(self: NazoPuyo[WaterField]): NazoPuyo[TsuField] {.inline.} =
  ## Converts the Water nazo puyo to the Tsu nazo puyo.
  result.environment = self.environment.toTsuEnvironment
  result.requirement = self.requirement

func toWaterNazoPuyo*(self: NazoPuyo[TsuField]): NazoPuyo[WaterField]
                     {.inline.} =
  ## Converts the Tsu nazo puyo to the Water nazo puyo.
  result.environment = self.environment.toWaterEnvironment
  result.requirement = self.requirement

# ------------------------------------------------
# Property
# ------------------------------------------------

func moveCount*(self): int {.inline.} = self.environment.pairs.len
  ## Returns the number of moves of the nazo puyo.

# ------------------------------------------------
# Flatten
# ------------------------------------------------

template flattenAnd*(nazos: NazoPuyos, body: untyped): untyped =
  ## Runs `body` with `nazoPuyo` exposed.
  case nazos.rule
  of Tsu:
    let nazoPuyo {.inject.} = nazos.tsu
    body
  of Water:
    let nazoPuyo {.inject.} = nazos.water
    body

# ------------------------------------------------
# Requirement <-> string
# ------------------------------------------------

const
  AllColors = collect:
    for color in RequirementColor:
      some color
  AllNumbers = collect:
    for num in RequirementNumber.low..RequirementNumber.high:
      some num

func `$`*(req: Requirement): string {.inline.} =
  result = $req.kind

  if req.color.isSome:
    result = result.replace("c", $req.color.get)

  if req.number.isSome:
    result = result.replace("n", $req.number.get)

func parseRequirement*(str: string): Requirement {.inline.} =
  ## Converts the string representation to the requirement.
  ## If `str` is not a valid representation, `ValueError` is raised.

  # NOTE: These variables should be const, but it makes compilation extremely
  # slow due to Nim's specification.
  {.push warning[ProveInit]:off.}
  let
    allRequirements = collect:
      for kind in RequirementKind:
        for color in (if kind in ColorKinds: Allcolors
                      else: @[none RequirementColor]):
          for num in (if kind in NumberKinds: AllNumbers
                      else: @[none RequirementNumber]):
            Requirement(kind: kind, color: color, number: num)
    strToRequirement = collect:
      for req in allRequirements:
        {$req: req}
  {.pop.}

  if str notin strToRequirement:
    raise newException(ValueError, "Invalid requirement: " & str)

  result = strToRequirement[str]

# ------------------------------------------------
# NazoPuyo <-> string
# ------------------------------------------------

const ReqEnvSep = "\n======\n"

func `$`*(self): string {.inline.} =
  $self.requirement & ReqEnvSep & $self.environment

func toString*(self): string {.inline.} = $self
  ## Converts the nazo puyo to the string representation.

func toString*(self; positions: Positions): string {.inline.} =
  ## Converts the nazo puyo and the positions to the string representation.
  ## If the pairs and the positions have different lengths,
  ## the longer one will be truncated.
  $self.requirement & ReqEnvSep & self.environment.toString positions

func parseNazoPuyo*[F: TsuField or WaterField](str: string):
    tuple[nazoPuyo: NazoPuyo[F], positions: Option[Positions]] {.inline.} =
  ## Converts the string representation to the nazo puyo.
  ## If `str` is not a valid representation, `ValueError` is raised.
  let strs = str.split ReqEnvSep
  if strs.len != 2:
    raise newException(ValueError, "Invalid nazo puyo: " & str)

  result.nazoPuyo.requirement = strs[0].parseRequirement
  (result.nazoPuyo.environment, result.positions) = strs[1].parseEnvironment[:F]

func parseTsuNazoPuyo*(str: string):
    tuple[nazoPuyo: NazoPuyo[TsuField], positions: Option[Positions]]
    {.inline.} =
  ## Converts the string representation to the Tsu nazo puyo.
  ## If `str` is not a valid representation, `ValueError` is raised.
  str.parseNazoPuyo[:TsuField]

func parseWaterNazoPuyo*(str: string):
    tuple[nazoPuyo: NazoPuyo[WaterField], positions: Option[Positions]]
    {.inline.} =
  ## Converts the string representation to the Water nazo puyo.
  ## If `str` is not a valid representation, `ValueError` is raised.
  str.parseNazoPuyo[:WaterField]

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

  IzumiyaUriKindKey = "req-kind"
  IzumiyaUriColorKey = "req-color"
  IzumiyaUriNumberKey = "req-number"

func toUriQuery*(req: Requirement, host: SimulatorHost): string {.inline.} =
  ## Converts the requirement to the URI query.
  case host
  of Izumiya:
    var queries = @[(IzumiyaUriKindKey, $req.kind.ord)]
    if req.kind in ColorKinds and req.color.isSome:
      queries.add (IzumiyaUriColorKey, $req.color.get.ord)
    if req.kind in NumberKinds and req.number.isSome:
      queries.add (IzumiyaUriNumberKey, $req.number.get)

    result = queries.encodeQuery
  of Ishikawa, Ips:
    let
      kindChar = KindToIshikawaUri[req.kind.ord]
      colorChar = if req.color.isSome: ColorToIshikawaUri[req.color.get.ord]
        else: EmptyIshikawaUri
      numChar = if req.number.isSome: NumberToIshikawaUri[req.number.get.ord]
        else: EmptyIshikawaUri

    result = kindChar & colorChar & numChar
  
func parseRequirement*(query: string, host: SimulatorHost): Requirement
                      {.inline.} =
  ## Converts the URI query to the requirement.
  ## If `query` is not a valid URI, `ValueError` is raised.
  {.push warning[ProveInit]:off.}
  var
    kind = none RequirementKind
    color = none RequirementColor
    num = none RequirementNumber
  {.pop.}

  case host
  of Izumiya:
    for key, val in query.decodeQuery:
      case key
      of IzumiyaUriKindKey:
        let kindInt = val.parseInt
        if kindInt < RequirementKind.low.ord or
            RequirementKind.high.ord < kindInt:
          raise newException(ValueError, "Invalid requirement: " & query)

        kind = some kindInt.RequirementKind
      of IzumiyaUriColorKey:
        var colorInt = val.parseInt
        if colorInt < RequirementColor.low.ord or
            RequirementColor.high.ord < colorInt:
          raise newException(ValueError, "Invalid requirement: " & query)

        color = some colorInt.RequirementColor
      of IzumiyaUriNumberKey:
        let numberInt = val.parseInt
        if numberInt < RequirementNumber.low.ord or
            RequirementNumber.high.ord < numberInt:
          raise newException(ValueError, "Invalid requirement: " & query)

        num = some numberInt.RequirementNumber
      else:
        raise newException(ValueError, "Invalid requirement: " & query)
  of Ishikawa, Ips:
    if query.len != 3 or query[0] notin IshikawaUriToKind or
        query[1] notin IshikawaUriToColor or query[2] notin IshikawaUriToNumber:
      raise newException(ValueError, "Invalid requirement: " & query)

    kind = some IshikawaUriToKind[query[0]]
    color = some IshikawaUriToColor[query[1]]
    num = some IshikawaUriToNumber[query[2]]

  if kind.isNone:
    raise newException(ValueError, "Invalid requirement: " & query)

  if kind.get in ColorKinds:
    if color.isNone:
      raise newException(ValueError, "Invalid requirement: " & query)
  else:
    color = none RequirementColor

  if kind.get in NumberKinds:
    if num.isNone:
      raise newException(ValueError, "Invalid requirement: " & query)
  else:
    num = none RequirementNumber

  result = Requirement(kind: kind.get, color: color, number: num)

# ------------------------------------------------
# NazoPuyo <-> URI
# ------------------------------------------------

const HostNameToHost = collect:
  for host in SimulatorHost:
    {$host: host}

func toUri(self; positions: Option[Positions], host: SimulatorHost,
           mode: IzumiyaSimulatorMode or IshikawaSimulatorMode): Uri
          {.inline.} =
  ## Converts the nazo puyo and the positions to the URI.
  ## The positions will be truncated if it is shorter than the pairs.
  result =
    if positions.isSome:
      self.environment.toUri(positions.get, host, IzumiyaSimulatorKind.Nazo,
                             mode)
    else:
      self.environment.toUri(host, IzumiyaSimulatorKind.Nazo, mode)

  let sep = case host
  of Izumiya: "&"
  of Ishikawa, Ips: "__"
  result.query &= sep & self.requirement.toUriQuery host

func toUri*(self; host = Izumiya,
            mode: IzumiyaSimulatorMode or IshikawaSimulatorMode = Play): Uri
           {.inline.} =
  ## Converts the nazo puyo to the URI.
  self.toUri(none Positions, host, mode)

func toUri*(self; positions: Positions, host = Izumiya,
            mode: IzumiyaSimulatorMode or IshikawaSimulatorMode = Play): Uri
           {.inline.} =
  ## Converts the nazo puyo and the positions to the URI.
  ## The positions will be truncated if it is shorter than the pairs.
  self.toUri(some positions, host, mode)

func parseNazoPuyo*[F: TsuField or WaterField](uri: Uri): tuple[
    nazoPuyo: NazoPuyo[F], positions: Option[Positions],
    izumiyaMode: Option[IzumiyaSimulatorMode],
    ishikawaMode: Option[IshikawaSimulatorMode]] {.inline.} =
  ## Converts the URI to the nazo puyo, positions and simulator mode.
  ## If `uri` is invalid, `ValueError` is raised.
  if uri.hostname notin HostNameToHost:
    raise newException(ValueError, "Invalid nazo puyo: " & $uri)

  let host = HostNameToHost[uri.hostname]

  {.push warning[ProveInit]:off.}
  var
    envUri = uri
    req = none Requirement
  {.pop.}

  case host
  of Izumiya:
    var
      reqQuery = newSeq[tuple[key: string, value: string]] 0
      envQuery = newSeq[tuple[key: string, value: string]] 0
    for key, value in uri.query.decodeQuery:
      case key
      of IzumiyaUriKindKey, IzumiyaUriColorKey, IzumiyaUriNumberKey:
        reqQuery.add (key, value)
      else:
        envQuery.add (key, value)

    envUri.query = envQuery.encodeQuery
    req = some reqQuery.encodeQuery.parseRequirement host
  of Ishikawa, Ips:
    let queries = uri.query.split "__"
    if queries.len != 2:
      raise newException(ValueError, "Invalid nazo puyo: " & $uri)

    envUri.query = queries[0]
    req = some queries[1].parseRequirement host

  if req.isNone:
    raise newException(ValueError, "Invalid nazo puyo: " & $uri)

  result.nazoPuyo.requirement = req.get
  let kind: Option[IzumiyaSimulatorKind]
  (result.nazoPuyo.environment, result.positions, kind, result.izumiyaMode,
   result.ishikawaMode) = envUri.parseEnvironment[:F]

func parseTsuNazoPuyo*(uri: Uri): tuple[
    nazoPuyo: NazoPuyo[TsuField], positions: Option[Positions],
    izumiyaMode: Option[IzumiyaSimulatorMode],
    ishikawaMode: Option[IshikawaSimulatorMode]] {.inline.} =
  ## Converts the URI to the Tsu nazo puyo, positions and simulator mode.
  ## If `uri` is invalid, `ValueError` is raised.
  uri.parseNazoPuyo[:TsuField]

func parseWaterNazoPuyo*(uri: Uri): tuple[
    nazoPuyo: NazoPuyo[WaterField], positions: Option[Positions],
    izumiyaMode: Option[IzumiyaSimulatorMode],
    ishikawaMode: Option[IshikawaSimulatorMode]] {.inline.} =
  ## Converts the URI to the Water nazo puyo, positions and simulator mode.
  ## If `uri` is invalid, `ValueError` is raised.
  uri.parseNazoPuyo[:WaterField]

func parseNazoPuyos*(uri: Uri): tuple[
    nazoPuyos: NazoPuyos, positions: Option[Positions],
    izumiyaMode: Option[IzumiyaSimulatorMode],
    ishikawaMode: Option[IshikawaSimulatorMode]] {.inline.} =
  ## Converts the URI to the nazo puyos, positions and simulator mode.
  ## If `uri` is invalid, `ValueError` is raised.
  try:
    (result.nazoPuyos.tsu, result.positions, result.izumiyaMode,
     result.ishikawaMode) = uri.parseTsuNazoPuyo
    result.nazoPuyos.rule = Tsu
  except ValueError:
    (result.nazoPuyos.water, result.positions, result.izumiyaMode,
     result.ishikawaMode) = uri.parseWaterNazoPuyo
    result.nazoPuyos.rule = Water
