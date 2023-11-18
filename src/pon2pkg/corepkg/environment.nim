## This module implements environments.
##

{.experimental: "strictDefs".}

import std/[options, random, sequtils, setutils, strutils, sugar, tables, uri]
import ./[cell, field, misc, moveresult, pair, position]

type
  Environment*[F: TsuField or WaterField] = object
    ## Puyo Puyo environment.
    field*: F
    pairs*: Pairs
    colors: set[ColorPuyo]
    rng: Rand

  Environments* = object
    ## Environment type that accepts all rules.
    rule*: Rule
    tsu*: Environment[TsuField]
    water*: Environment[WaterField]

  IshikawaMode = enum
    ## Ishikawa-simulator mode.
    Edit = "e"
    Simu = "s"
    View = "v"
    Nazo = "n"

# ------------------------------------------------
# Convert
# ------------------------------------------------

func toTsuEnvironment*(self: Environment[WaterField]): Environment[TsuField]
                      {.inline.} =
  ## Converts the field type to Tsu.
  result.field = self.field.toTsuField
  result.pairs = self.pairs
  result.colors = self.colors
  result.rng = self.rng

func toWaterEnvironment*(self: Environment[TsuField]): Environment[WaterField]
                        {.inline.} =
  ## Converts the field type to Water.
  result.field = self.field.toWaterField
  result.pairs = self.pairs
  result.colors = self.colors
  result.rng = self.rng

# ------------------------------------------------
# Flatten
# ------------------------------------------------

template flattenAnd*(environments: Environments, body: untyped): untyped =
  ## Runs `body` with `environment` exposed.
  case environments.rule
  of Tsu:
    let environment {.inject.} = environments.tsu
    body
  of Water:
    let environment {.inject.} = environments.water
    body

# ------------------------------------------------
# Pair
# ------------------------------------------------

func randomPair(rng: var Rand, colors: set[ColorPuyo]): Pair {.inline.} =
  ## Returns a random pair using the given colors.
  let
    idxes = colors.mapIt it.ord - ColorPuyo.low.ord
    axisIdx = rng.sample idxes
    childIdx = rng.sample idxes

  result = Pair.low.succ axisIdx * ColorPuyo.fullSet.card + childIdx

func addPair*[F: TsuField or WaterField](mSelf: var Environment[F]) {.inline.} =
  ## Adds a random pair to the tail of the pairs.
  mSelf.pairs.addLast mSelf.rng.randomPair mSelf.colors

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func randomColors(rng: var Rand, colorCount: range[1..5]): set[ColorPuyo]
                 {.inline.} =
  var colors = [Red.ColorPuyo, Green, Blue, Yellow, Purple]
  rng.shuffle colors

  result = {}
  for i in 0..<colorCount:
    result.incl colors[i]

func setInitialPairs[F: TsuField or WaterField](mSelf: var Environment[F])
                    {.inline.} =
  ## Sets the first two pairs.
  let initialColors = mSelf.rng.randomColors min(mSelf.colors.card, 3)
  for _ in 0..<2:
    mSelf.pairs.addLast mSelf.rng.randomPair initialColors

func reset[F: TsuField or WaterField](
    mSelf: var Environment[F], seed: Option[int], resetColors: bool,
    setPairs: bool) {.inline.} =
  ## Resets the environment.
  if resetColors:
    var rng = if seed.isSome: seed.get.initRand else: mSelf.rng
    mSelf.colors = rng.randomColors mSelf.colors.card

  if seed.isSome:
    mSelf.rng = seed.get.initRand

  mSelf.field = zeroField[mSelf.F]()

  mSelf.pairs.clear
  if setPairs:
    mSelf.setInitialPairs
    mSelf.addPair

func reset*[F: TsuField or WaterField](
    mSelf: var Environment[F], seed: int, resetColors = true, setPairs = true)
    {.inline.} =
  ## Resets the environment.
  mSelf.reset some seed, resetColors, setPairs

func reset*[F: TsuField or WaterField](
    mSelf: var Environment[F], resetColors = true, setPairs = true) {.inline.} =
  ## Resets the environment.
  {.push warning[ProveInit]: off.}
  mSelf.reset none int, resetColors, setPairs
  {.pop.}

func initEnvironment*[F: TsuField or WaterField](
    seed: int, colors = set[ColorPuyo]({}), colorCount = range[1..5](4),
    setPairs = true): Environment[F] {.inline.} =
  ## Returns the initial environment.
  ## If `colors` is given, `colorCount` will be ignored.
  if colors.card > 0:
    result.colors = colors
  else:
    var rng = seed.initRand
    result.colors = rng.randomColors colorCount

  result.reset some seed, false, setPairs

func initTsuEnvironment*(
    seed: int, colors = set[ColorPuyo]({}), colorCount = range[1..5](4),
    setPairs = true): Environment[TsuField] {.inline.} =
  ## Returns the initial Tsu environment.
  ## If `colors` is given, `colorCount` will be ignored.
  initEnvironment[TsuField](seed, colors, colorCount, setPairs)

func initWaterEnvironment*(
    seed: int, colors = set[ColorPuyo]({}), colorCount = range[1..5](4),
    setPairs = true): Environment[WaterField] {.inline.} =
  ## Returns the initial Water environment.
  ## If `colors` is given, `colorCount` will be ignored.
  initEnvironment[WaterField](seed, colors, colorCount, setPairs)

proc initEnvironment*[F: TsuField or WaterField](
    colors = set[ColorPuyo]({}), colorCount = range[1..5](4),
    setPairs = true): Environment[F] {.inline.} =
  ## Returns the initial environment.
  ## If `colors` is given, `colorCount` will be ignored.
  ## `random.randomize()` should be called before this procedure is called.
  initEnvironment[F](rand int.low..int.high, colors, colorCount, setPairs)

proc initTsuEnvironment*(
    colors = set[ColorPuyo]({}), colorCount = range[1..5](4),
    setPairs = true): Environment[TsuField] {.inline.} =
  ## Returns the initial Tsu environment.
  ## If `colors` is given, `colorCount` will be ignored.
  ## `random.randomize()` should be called before this procedure is called.
  initEnvironment[TsuField](colors, colorCount, setPairs)

proc initWaterEnvironment*(
    colors = set[ColorPuyo]({}), colorCount = range[1..5](4),
    setPairs = true): Environment[WaterField] {.inline.} =
  ## Returns the initial Water environment.
  ## If `colors` is given, `colorCount` will be ignored.
  ## `random.randomize()` should be called before this procedure is called.
  initEnvironment[WaterField](colors, colorCount, setPairs)

# ------------------------------------------------
# Count - Puyo
# ------------------------------------------------

func puyoCount*[F: TsuField or WaterField](self: Environment[F], puyo: Puyo):
    int {.inline.} =
  ## Returns the number of `puyo` in the environment.
  self.field.puyoCount(puyo) + self.pairs.puyoCount(puyo)

func puyoCount*[F: TsuField or WaterField](self: Environment[F]): int
               {.inline.} =
  ## Returns the number of puyos in the environment.
  self.field.puyoCount + self.pairs.puyoCount

# ------------------------------------------------
# Count - Color
# ------------------------------------------------

func colorCount*[F: TsuField or WaterField](self: Environment[F]): int
                {.inline.} =
  ## Returns the number of color puyos in the environment.
  self.field.colorCount + self.pairs.colorCount

# ------------------------------------------------
# Count - Garbage
# ------------------------------------------------

func garbageCount*[F: TsuField or WaterField](self: Environment[F]): int
                  {.inline.} =
  ## Returns the number of garbage puyos in the environment.
  self.field.garbageCount + self.pairs.garbageCount

# ------------------------------------------------
# Move
# ------------------------------------------------

func move*[F: TsuField or WaterField](
    mSelf: var Environment[F], pos: Position, addPair = true): MoveResult
    {.inline, discardable.} =
  ## Puts the pair and advance the field until chains end,
  ## and then adds a new pair to the environment (optional).
  ## This function tracks:
  ## - Number of chains
  result = mSelf.field.move(mSelf.pairs.popFirst, pos)

  if addPair:
    mSelf.addPair

func moveWithRoughTracking*[F: TsuField or WaterField](
    mSelf: var Environment[F], pos: Position, addPair = true): MoveResult
    {.inline.} =
  ## Puts the pair and advance the field until chains end,
  ## and then adds a new pair to the environment (optional).
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  result = mSelf.field.moveWithRoughTracking(mSelf.pairs.popFirst, pos)

  if addPair:
    mSelf.addPair

func moveWithDetailTracking*[F: TsuField or WaterField](
    mSelf: var Environment[F], pos: Position, addPair = true): MoveResult
    {.inline.} =
  ## Puts the pair and advance the field until chains end,
  ## and then adds a new pair to the environment (optional).
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  result = mSelf.field.moveWithDetailTracking(mSelf.pairs.popFirst, pos)

  if addPair:
    mSelf.addPair

func moveWithFullTracking*[F: TsuField or WaterField](
    mSelf: var Environment[F], pos: Position, addPair = true): MoveResult
    {.inline.} =
  ## Puts the pair and advance the field until chains end,
  ## and then adds a new pair to the environment (optional).
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  ## - Number of color puyos in each connected component that disappeared \
  ## in each chain
  result = mSelf.field.moveWithFullTracking(mSelf.pairs.popFirst, pos)

  if addPair:
    mSelf.addPair

# ------------------------------------------------
# Environment <-> string
# ------------------------------------------------

const
  FieldPairsSep = "\n------\n"
  PairPosSep = '|'
  PairsSep = "\n"

func `$`*[F: TsuField or WaterField](self: Environment[F]): string {.inline.} =
  $self.field & FieldPairsSep & $self.pairs

func toString*[F: TsuField or WaterField](self: Environment[F]): string
              {.inline.} =
  ## Converts the environment to the string representation.
  $self

func toString*[F: TsuField or WaterField](
    self: Environment[F], positions: Positions): string {.inline.} =
  ## Converts the environment and the positions to the string representation.
  ## If the pairs and the positions have different lengths,
  ## the longer one will be truncated.
  let
    pairPositionStrs = collect:
      for i in 0..<min(self.pairs.len, positions.len):
        let
          pair = self.pairs[i]
          pos = positions[i]
        $pair & PairPosSep & $pos
    pairPositionStr = pairPositionStrs.join PairsSep

  result = $self.field & FieldPairsSep & pairPositionStr

func parseEnvironment*[F: TsuField or WaterField](
    str: string, colors = ColorPuyo.fullSet, seed = 0): tuple[
      environment: Environment[F], positions: Option[Positions]] {.inline.} =
  ## Converts the string representation to the environment and positions.
  ## If `str` is not a valid representation, `ValueError` is raised.
  let strs = str.split FieldPairsSep
  if strs.len != 2:
    raise newException(ValueError, "Invalid environment: " & str)

  result.environment.field = strs[0].parseField[:F]

  {.push warning[ProveInit]: off.}
  result.positions = none Positions
  {.pop.}

  try:
    result.environment.pairs = strs[1].parsePairs
  except ValueError:
    let pairPositionStrs = strs[1].split(PairsSep).mapIt it.split PairPosSep
    if pairPositionStrs.anyIt it.len != 2:
      raise newException(ValueError, "Invalid environment: " & str)

    result.environment.pairs = toDeque pairPositionStrs.mapIt it[0].parsePair
    result.positions = some pairPositionStrs.mapIt it[1].parsePosition

  result.environment.colors = colors
  result.environment.rng = seed.initRand

func parseTsuEnvironment*(str: string, colors = ColorPuyo.fullSet, seed = 0):
    tuple[environment: Environment[TsuField], positions: Option[Positions]]
    {.inline.} =
  ## Converts the string representation to the Tsu environment and positions.
  ## If `str` is not a valid representation, `ValueError` is raised.
  str.parseEnvironment[:TsuField](colors, seed)

func parseWaterEnvironment*(str: string, colors = ColorPuyo.fullSet, seed = 0):
    tuple[environment: Environment[WaterField], positions: Option[Positions]]
    {.inline.} =
  ## Converts the string representation to the Water environment and positions.
  ## If `str` is not a valid representation, `ValueError` is raised.
  str.parseEnvironment[:WaterField](colors, seed)

# ------------------------------------------------
# Environment <-> URI
# ------------------------------------------------

const
  UriToKind = collect:
    for kind in SimulatorKind:
      {$kind: kind}
  UriToMode = collect:
    for mode in SimulatorMode:
      {$mode: mode}

  PathToIshikawaMode = collect:
    for mode in IshikawaMode:
      {"/simu/p" & $mode & ".html": mode}

  EditorKey = "editor"
  KindKey = "kind"
  ModeKey = "mode"
  FieldKey = "field"
  PairsKey = "pairs"
  PositionsKey = "positions"

func toUri[F: TsuField or WaterField](
    self: Environment[F], positions: Option[Positions], host: SimulatorHost,
    kind: SimulatorKind, mode: SimulatorMode, editor: bool): Uri {.inline.} =
  ## Converts the environment and the positions to the URI.
  ## The positions will be truncated if it is shorter than the pairs.
  ## If `mode` is `Edit`, `editor` will be ignored (*i.e.*, regarded as `true`).
  let positions2 =
    if positions.isNone: Position.none.repeat self.pairs.len
    elif positions.get.len > self.pairs.len: positions.get[0 ..< self.pairs.len]
    else: positions.get

  result.scheme = if host == Ips: "http" else: "https"
  result.hostname = $host

  case host
  of Izumiya:
    result.path = "/pon2/playground/index.html"

    var queries = newSeqOfCap[(string, string)] 6
    if editor or mode == SimulatorMode.Edit:
      queries.add (EditorKey, "")
    queries &= [(KindKey, $kind), (ModeKey, $mode),
                (FieldKey, self.field.toUriQuery host),
                (PairsKey, self.pairs.toUriQuery host)]
    if positions.isSome:
      queries.add (PositionsKey, positions2.toUriQuery host)

    result.query = queries.encodeQuery
  of Ishikawa, Ips:
    let ishikawaMode =
      if editor:
        case kind
        of SimulatorKind.Regular:
          case mode
          of Play: Simu
          of SimulatorMode.Edit: IshikawaMode.Edit
        of SimulatorKind.Nazo: IshikawaMode.Nazo
      else:
        View

    result.path = "/simu/p" & $ishikawaMode & ".html"

    let
      pairPositionUris = collect:
        for i in 0..<self.pairs.len:
          let
            pair = self.pairs[i]
            pos = positions2[i]
          pair.toUriQuery(host) & pos.toUriQuery(host)
      pairPositionUri = pairPositionUris.join
    result.query = self.field.toUriQuery(host) & '_' & pairPositionUri

func toUri*[F: TsuField or WaterField](
    self: Environment[F], host = Izumiya, kind = Regular, mode = Play,
    editor = false): Uri {.inline.} =
  ## Converts the environment and the positions to the URI.
  self.toUri(none Positions, host, kind, mode, editor)

func toUri*[F: TsuField or WaterField](
    self: Environment[F], positions: Positions, host = Izumiya, kind = Regular,
    mode = Play, editor = false): Uri {.inline.} =
  ## Converts the environment and the positions to the URI.
  ## The positions will be truncated if it is shorter than the pairs.
  self.toUri(some positions, host, kind, mode, editor)

func parseEnvironment*[F: TsuField or WaterField](
    uri: Uri, colors = ColorPuyo.fullSet, seed = 0): tuple[
      environment: Environment[F], positions: Option[Positions],
      kind: SimulatorKind, mode: SimulatorMode, editor: bool] {.inline.} =
  ## Converts the URI to the environment, positions and simulator properties.
  ## If `uri` is not a valid URI, `ValueError` is raised.
  {.push warning[ProveInit]: off.}
  result.positions = none Positions
  result.editor = false
  var
    field = none F
    pairs = none Pairs
    kind = none SimulatorKind
    mode = none SimulatorMode
  {.pop.}

  case uri.hostname
  of $Izumiya:
    if uri.path != "/pon2/playground/index.html":
      raise newException(ValueError, "Invalid environment: " & $uri)

    for (key, val) in uri.query.decodeQuery:
      case key
      of EditorKey:
        result.editor = val.toLowerAscii notin ["false", "off"]
      of KindKey:
        if val notin UriToKind:
          raise newException(ValueError, "Invalid environment: " & $uri)
        kind = some UriToKind[val]
      of ModeKey:
        if val notin UriToMode:
          raise newException(ValueError, "Invalid environment: " & $uri)
        mode = some UriToMode[val]
      of FieldKey:
        field = some val.parseField[:F](Izumiya)
      of PairsKey:
        pairs = some val.parsePairs Izumiya
      of PositionsKey:
        result.positions = some val.parsePositions Izumiya
      else:
        raise newException(ValueError, "Invalid environment: " & $uri)

    if kind.isNone or mode.isNone:
      raise newException(ValueError, "Invalid environment: " & $uri)

    if mode.get == SimulatorMode.Edit:
      result.editor = true
  of $Ishikawa, $Ips:
    # kind, mode, editor
    if uri.path notin PathToIshikawaMode:
      raise newException(ValueError, "Invalid environment: " & $uri)
    case PathToIshikawaMode[uri.path]
    of IshikawaMode.Edit:
      kind = some Regular
      mode = some SimulatorMode.Edit
      result.editor = true
    of Simu:
      kind = some Regular
      mode = some Play
      result.editor = true
    of View:
      kind = some Regular
      mode = some Play
      result.editor = false
    of IshikawaMode.Nazo:
      kind = some SimulatorKind.Nazo
      mode = some Play
      result.editor = true

    # field, pairs, positions
    let
      host = if uri.hostname == $Ishikawa: Ishikawa else: Ips
      strs = uri.query.split '_'
    case strs.len
    of 1:
      pairs = some initDeque[Pair]()
      result.positions = some newSeq[Option[Position]]()
    of 2:
      if strs[1].len mod 2 != 0:
        raise newException(ValueError, "Invalid environment: " & $uri)

      let pairsCount = strs[1].len div 2
      var
        pairsSeq = newSeqOfCap[Pair] pairsCount
        positions = newSeqOfCap[Option[Position]] pairsCount

      for i in 0..<pairsCount:
        pairsSeq.add ($strs[1][2 * i]).parsePair host
        positions.add ($strs[1][2 * i + 1]).parsePosition host

      pairs = some pairsSeq.toDeque
      result.positions = some positions
    else:
      raise newException(ValueError, "Invalid environment: " & $uri)

    field = some strs[0].parseField[:F](host)
  else:
    raise newException(ValueError, "Invalid environment: " & $uri)

  if field.isNone or pairs.isNone:
    raise newException(ValueError, "Invalid environment: " & $uri)

  result.environment.field = field.get
  result.environment.pairs = pairs.get
  result.environment.colors = colors
  result.environment.rng = seed.initRand
  result.kind = kind.get
  result.mode = mode.get

func parseTsuEnvironment*(
    uri: Uri, colors = ColorPuyo.fullSet, seed = 0): tuple[
      environment: Environment[TsuField], positions: Option[Positions],
      kind: SimulatorKind, mode: SimulatorMode, editor: bool] {.inline.} =
  ## Converts the URI to the Tsu environment, positions and simulator mode.
  ## If `uri` is not a valid URI, `ValueError` is raised.
  uri.parseEnvironment[:TsuField](colors, seed)

func parseWaterEnvironment*(
    uri: Uri, colors = ColorPuyo.fullSet, seed = 0): tuple[
      environment: Environment[WaterField], positions: Option[Positions],
      kind: SimulatorKind, mode: SimulatorMode, editor: bool] {.inline.} =
  ## Converts the URI to the Water environment, positions and simulator mode.
  ## If `uri` is not a valid URI, `ValueError` is raised.
  uri.parseEnvironment[:WaterField](colors, seed)

func parseEnvironments*(
    uri: Uri, colors = ColorPuyo.fullSet, seed = 0): tuple[
      environments: Environments, positions: Option[Positions],
      kind: SimulatorKind, mode: SimulatorMode, editor: bool] {.inline.} =
  ## Converts the URI to the environments, positions and simulator mode.
  ## If `uri` is not a valid URI, `ValueError` is raised.
  try:
    (result.environments.tsu, result.positions, result.kind, result.mode,
     result.editor) = uri.parseTsuEnvironment(colors, seed)
    result.environments.rule = Tsu
  except ValueError:
    (result.environments.water, result.positions, result.kind, result.mode,
     result.editor) = uri.parseWaterEnvironment(colors, seed)
    result.environments.rule = Water

# ------------------------------------------------
# Environment <-> array
# ------------------------------------------------

func toArrays*[F: TsuField or WaterField](self: Environment[F]):
    tuple[field: array[Row, array[Column, Cell]], pairs: seq[array[2, Cell]]]
    {.inline.} =
  ## Converts the environment to the arrays.
  result.field = self.field.toArray
  result.pairs = self.pairs.toArray

func parseEnvironment*[F: TsuField or WaterField](
    fieldArr: array[Row, array[Column, Cell]],
    pairsArr: openArray[array[2, ColorPuyo]], colors = ColorPuyo.fullSet,
    seed = 0): Environment[F] {.inline.} =
  ## Converts the arrays to the environment.
  result.field = fieldArr.parseField[:F]
  result.pairs = pairsArr.parsePairs
  result.colors = colors
  result.rng = seed.initRand

func parseTsuEnvironment*(
    fieldArr: array[Row, array[Column, Cell]],
    pairsArr: openArray[array[2, ColorPuyo]], colors = ColorPuyo.fullSet,
    seed = 0): Environment[TsuField] {.inline.} =
  ## Converts the arrays to the Tsu environment.
  fieldArr.parseEnvironment[:TsuField](pairsArr, colors, seed)

func parseWaterEnvironment*(
    fieldArr: array[Row, array[Column, Cell]],
    pairsArr: openArray[array[2, ColorPuyo]], colors = ColorPuyo.fullSet,
    seed = 0): Environment[WaterField] {.inline.} =
  ## Converts the arrays to the Water environment.
  fieldArr.parseEnvironment[:WaterField](pairsArr, colors, seed)
