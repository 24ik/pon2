## This module implements nodes of solution search tree.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[options, sequtils, setutils, strutils, sugar, tables, uri]
import ./[mark]
import ../[misc]
import ../../corepkg/[cell, environment, field, misc, moveresult, pair,
                      position]
import ../../nazopuyopkg/[nazopuyo]

type Node*[F: TsuField or WaterField] = object
  ## Node of solution search tree.
  environment: Environment[F]
  requirement: Requirement

  positions: Positions
  moveResult: MoveResult

  # cumulative data
  disappearedColors: set[ColorPuyo]
  disappearedCount: int

  # number of color puyos that do not disappear yet
  fieldCounts: array[ColorPuyo, int]
  pairsCounts: array[ColorPuyo, int]
  garbageCount: int

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func initNode*[F: TsuField or WaterField](nazo: NazoPuyo[F]): Node[F]
              {.inline.} =
  ## Constructor of `Node`.
  result.environment = nazo.environment
  result.requirement = nazo.requirement

  result.positions = newSeqOfCap[Option[Position]](nazo.moveCount)
  result.moveResult = initMoveResult(0, [0, 0, 0, 0, 0, 0, 0], @[], @[])

  result.disappearedColors = {}
  result.disappearedCount = 0

  for color in ColorPuyo:
    result.fieldCounts[color] = nazo.environment.field.puyoCount color
    result.pairsCounts[color] = nazo.environment.pairs.puyoCount color
  result.garbageCount = nazo.environment.field.garbageCount

# ------------------------------------------------
# Property
# ------------------------------------------------

func colorCount[F: TsuField or WaterField](
    node: Node[F], color: ColorPuyo): int {.inline.} =
  ## Returns the number of `color` puyos that do not disappear yet
  node.fieldCounts[color] + node.pairsCounts[color]

func isLeaf[F: TsuField or WaterField](node: Node[F]): bool {.inline.} =
  ## Returns `true` if the node is a leaf; *i.e.*, all moves are completed.
  node.environment.pairs.len == 0 or node.environment.field.isDead

# ------------------------------------------------
# Child
# ------------------------------------------------

const ReqColorToPuyo = {
  RequirementColor.Garbage: Cell.Garbage.Puyo,
  RequirementColor.Red: Cell.Red.Puyo,
  RequirementColor.Green: Cell.Green.Puyo,
  RequirementColor.Blue: Cell.Blue.Puyo,
  RequirementColor.Yellow: Cell.Yellow.Puyo,
  RequirementColor.Purple: Cell.Purple.Puyo}.toTable

func child[F: TsuField or WaterField](
    node: Node[F], pos: Position, reqKind: static RequirementKind,
    reqColor: static RequirementColor): Node[F] {.inline.} =
  ## Returns the child node with the `pos` edge.
  let
    firstPair = node.environment.pairs.peekFirst
    moveFn =
      when reqKind in {Clear, DisappearColor, DisappearColorMore,
                       DisappearCount, DisappearCountMore, Chain, ChainMore,
                       ChainClear, ChainMoreClear}:
        environment.moveWithRoughTracking[F]
      elif reqKind in {DisappearColorSametime, DisappearColorMoreSametime,
                       DisappearCountSametime, DisappearCountMoreSametime}:
        environment.moveWithDetailTracking[F]
      else:
        environment.moveWithFullTracking[F]

  discard firstPair # HACK: dummy to remove warning

  result = node
  result.positions.add some pos
  result.moveResult = result.environment.moveFn(pos, false)

  # update cumulative data
  when reqKind in {DisappearColor, DisappearColorMore}:
    result.disappearedColors.incl result.moveResult.colors
  elif reqKind in {DisappearCount, DisappearCountMore}:
    when reqColor == RequirementColor.All:
      result.disappearedCount.inc result.moveResult.puyoCount
    elif reqColor == RequirementColor.Color:
      result.disappearedCount.inc result.moveResult.colorCount
    elif reqColor == RequirementColor.Garbage:
      result.disappearedCount.inc result.moveResult.garbageCount
    else:
      result.disappearedCount.inc result.moveResult.puyoCount ReqColorToPuyo[
        reqColor]

  # update fieldCounts, pairsCounts
  when reqKind notin {DisappearColor, DisappearColorMore}:
    when reqColor in {RequirementColor.All, RequirementColor.Color,
                      RequirementColor.Garbage}:
      for color in ColorPuyo:
        result.fieldCounts[color] = result.environment.field.puyoCount color
    else:
      let puyo = ReqColorToPuyo[reqColor]
      result.fieldCounts[puyo] = result.environment.field.puyoCount puyo

    result.pairsCounts[firstPair.axis].dec
    result.pairsCounts[firstPair.child].dec

  # update garbageCount
  when reqKind in {Clear, DisappearCount, DisappearCountMore, ChainClear,
                   ChainMoreClear, DisappearCountSametime,
                   DisappearCountMoreSametime}:
    when reqColor in {RequirementColor.All, RequirementColor.Garbage}:
      result.garbageCount.dec result.moveResult.garbageCount

func children*[F: TsuField or WaterField](
    node: Node[F], reqKind: static RequirementKind,
    reqColor: static RequirementColor): seq[Node[F]] {.inline.} =
  ## Returns the children of the node.
  let positions =
    if node.environment.pairs.peekFirst.isDouble:
      node.environment.field.validDoublePositions
    else:
      node.environment.field.validPositions

  result = positions.mapIt node.child(it, reqKind, reqColor)

# ------------------------------------------------
# Accept
# ------------------------------------------------

func isAccepted[F: TsuField or WaterField](
    node: Node[F], reqKind: static RequirementKind,
    reqColor: static RequirementColor): bool {.inline.} =
  ## Returns `true` if the requirement is satisfied.
  # check if the field is clear
  when reqKind in {Clear, ChainClear, ChainMoreClear}:
    let fieldCount: int
    when reqColor == RequirementColor.All:
      fieldCount = node.fieldCounts.sum2 + node.garbageCount
    elif reqColor == RequirementColor.Color:
      fieldCount = node.fieldCounts.sum2
    elif reqColor == RequirementColor.Garbage:
      fieldCount = node.garbageCount
    else:
      fieldCount = node.fieldCounts[ReqColorToPuyo[reqColor]]

    if fieldCount > 0:
      return false

  # check if the requirement is satisfied
  when reqKind == Clear:
    result = true
  elif reqKind in {DisappearColor, DisappearColorMore}:
    result = node.requirement.disappearColorSatisfied(
      node.disappearedColors, reqKind)
  elif reqKind in {DisappearCount, DisappearCountMore}:
    result = node.requirement.disappearCountSatisfied(
      node.disappearedCount, reqKind)
  elif reqKind in {Chain, ChainMore, ChainClear, ChainMoreClear}:
    result = node.requirement.chainSatisfied(node.moveResult, reqKind)
  elif reqKind in {DisappearColorSametime, DisappearColorMoreSametime}:
    result = node.requirement.disappearColorSametimeSatisfied(
      node.moveResult, reqKind)
  elif reqKind in {DisappearCountSametime, DisappearCountMoreSametime}:
    result = node.requirement.disappearCountSametimeSatisfied(
      node.moveResult, reqKind, reqColor)
  elif reqKind in {DisappearPlace, DisappearPlaceMore}:
    result = node.requirement.disappearPlaceSatisfied(
      node.moveResult, reqKind, reqColor)
  elif reqKind in {DisappearConnect, DisappearConnectMore}:
    result = node.requirement.disappearConnectSatisfied(
      node.moveResult, reqKind, reqColor)
  else:
    assert false

# ------------------------------------------------
# Prune
# ------------------------------------------------

func filter4[T: SomeNumber or Natural](x: T): T {.inline.} = x * (x >= 4).T
  ## If `x` is equal or greater than 4, returns `x`; otherwise returns 0.

func canPrune*[F: TsuField or WaterField](
    node: Node[F], reqKind: static RequirementKind,
    reqColor: static RequirementColor, firstCall: static bool = false): bool
    {.inline.} =
  ## Returns `true` if the node is unsolvable.
  # check if it is possible to clear the field
  when reqKind in {Clear, ChainClear, ChainMoreClear}:
    let canPrune: bool
    when reqColor == RequirementColor.All:
      var
        hasNotDisappearableColor = false
        hasDisappearableColor = false

      for color in ColorPuyo:
        if node.fieldCounts[color] > 0:
          if node.colorCount(color) >= 4:
            hasDisappearableColor = true
            break
          else:
            hasNotDisappearableColor = true
            break

      canPrune = hasNotDisappearableColor or (
        node.garbageCount > 0 and not hasDisappearableColor)
    elif reqColor == RequirementColor.Color:
      canPrune = (ColorPuyo.low..ColorPuyo.high).anyIt(
        node.fieldCounts[it] > 0 and node.colorCount(it) < 4)
    elif reqColor == RequirementColor.Garbage:
      canPrune = node.garbageCount > 0 and
        (ColorPuyo.low..ColorPuyo.high).allIt node.colorCount(it) < 4
    else:
      const color = ReqColorToPuyo[reqColor]
      canPrune = node.fieldCounts[color] > 0 and node.colorCount(color) < 4

    if canPrune:
      return true

  # requirement-specific pruning
  when reqKind == Clear:
    result = false
  elif reqKind in {DisappearColor, DisappearColorMore}:
    when firstCall:
      result = (ColorPuyo.low..ColorPuyo.high).countIt(
        node.colorCount(it) >= 4) < node.requirement.number.get
    else:
      result = false
  elif reqKind in {DisappearCount, DisappearCountMore, DisappearCountSametime,
                   DisappearCountMoreSametime, DisappearConnect,
                   DisappearConnectMore}:
    let nowPossibleCount: int
    when reqColor in {RequirementColor.All, RequirementColor.Color,
                      RequirementColor.Garbage}:
      let colorPossibleCount = (ColorPuyo.low..ColorPuyo.high).mapIt(
        node.colorCount(it).filter4).sum2

      nowPossibleCount =
        when reqColor == RequirementColor.All:
          colorPossibleCount + (colorPossibleCount > 0).int * node.garbageCount
        elif reqColor == RequirementColor.Color:
          colorPossibleCount
        elif reqColor == RequirementColor.Garbage:
          assert reqKind notin {DisappearConnect, DisappearConnectMore}
          (colorPossibleCount > 0).int * node.garbageCount
        else:
          assert false
          0
    else:
      nowPossibleCount = node.colorCount(ReqColorToPuyo[reqColor]).filter4

    let possibleCount =
      when reqKind in {DisappearCount, DisappearCountMore}:
        node.disappearedCount + nowPossibleCount
      elif reqKind in {DisappearCountSametime, DisappearCountMoreSametime,
                       DisappearConnect, DisappearConnectMore}:
        nowPossibleCount
      else:
        assert false
        0

    result = possibleCount < node.requirement.number.get
  elif reqKind in {Chain, ChainMore, ChainClear, ChainMoreClear}:
    let possibleChain =
      sum2 (ColorPuyo.low..ColorPuyo.high).mapIt node.colorCount(it) div 4
    result = possibleChain < node.requirement.number.get
  elif reqKind in {DisappearColorSametime, DisappearColorMoreSametime}:
    let possibleColorCount =
      (ColorPuyo.low..ColorPuyo.high).countIt node.colorCount(it) >= 4
    result = possibleColorCount < node.requirement.number.get
  elif reqKind in {DisappearPlace, DisappearPlaceMore}:
    let possiblePlace: int
    when reqColor in {RequirementColor.All, RequirementColor.Color}:
      possiblePlace =
        sum2 (ColorPuyo.low..ColorPuyo.high).mapIt (node.colorCount(it) div 4)
    elif reqColor == RequirementColor.Garbage:
      assert false
      possiblePlace = 0
    else:
      possiblePlace = node.colorCount(ReqColorToPuyo[reqColor]) div 4

    result = possiblePlace < node.requirement.number.get
  else:
    assert false

# ------------------------------------------------
# Solve
# ------------------------------------------------

func solve*[F: TsuField or WaterField](
    node: Node[F], reqKind: static RequirementKind,
    reqColor: static RequirementColor, earlyStopping: static bool):
    seq[Positions] {.inline.} =
  ## Solves the nazo puyo.
  if node.isAccepted(reqKind, reqColor):
    return @[node.positions]
  if node.isLeaf or node.canPrune(reqKind, reqColor):
    return @[]

  result = @[]
  for child in node.children(reqKind, reqColor):
    result &= child.solve(reqKind, reqColor, earlyStopping)

    when earlyStopping:
      if result.len > 1:
        return

func solve[F: TsuField or WaterField](
    node: Node[F], reqKind: static RequirementKind,
    earlyStopping: static bool): seq[Positions] {.inline.} =
  ## Solves the nazo puyo.
  assert reqKind in {
    RequirementKind.Clear, DisappearCount, DisappearCountMore, ChainClear,
    ChainMoreClear, DisappearCountSametime, DisappearCountMoreSametime,
    DisappearPlace, DisappearPlaceMore, DisappearConnect, DisappearConnectMore}

  result = case node.requirement.color.get
  of RequirementColor.All:
    node.solve(reqKind, RequirementColor.All, earlyStopping)
  of RequirementColor.Red:
    node.solve(reqKind, RequirementColor.Red, earlyStopping)
  of RequirementColor.Green:
    node.solve(reqKind, RequirementColor.Green, earlyStopping)
  of RequirementColor.Blue:
    node.solve(reqKind, RequirementColor.Blue, earlyStopping)
  of RequirementColor.Yellow:
    node.solve(reqKind, RequirementColor.Yellow, earlyStopping)
  of RequirementColor.Purple:
    node.solve(reqKind, RequirementColor.Purple, earlyStopping)
  of RequirementColor.Garbage:
    node.solve(reqKind, RequirementColor.Garbage, earlyStopping)
  of RequirementColor.Color:
    node.solve(reqKind, RequirementColor.Color, earlyStopping)

func solve*[F: TsuField or WaterField](
    node: Node[F], earlyStopping: static bool = false): seq[Positions]
    {.inline.} =
  ## Solves the nazo puyo.
  const DummyColor = RequirementColor.All

  result = case node.requirement.kind
  of RequirementKind.Clear:
    node.solve(RequirementKind.Clear, earlyStopping)
  of DisappearColor:
    node.solve(DisappearColor, DummyColor, earlyStopping)
  of DisappearColorMore:
    node.solve(DisappearColorMore, DummyColor, earlyStopping)
  of DisappearCount:
    node.solve(DisappearCount, earlyStopping)
  of DisappearCountMore:
    node.solve(DisappearCountMore, earlyStopping)
  of Chain:
    node.solve(Chain, DummyColor, earlyStopping)
  of ChainMore:
    node.solve(ChainMore, DummyColor, earlyStopping)
  of ChainClear:
    node.solve(ChainClear, earlyStopping)
  of ChainMoreClear:
    node.solve(ChainMoreClear, earlyStopping)
  of DisappearColorSametime:
    node.solve(DisappearColorSametime, DummyColor, earlyStopping)
  of DisappearColorMoreSametime:
    node.solve(DisappearColorMoreSametime, DummyColor, earlyStopping)
  of DisappearCountSametime:
    node.solve(DisappearCountSametime, earlyStopping)
  of DisappearCountMoreSametime:
    node.solve(DisappearCountMoreSametime, earlyStopping)
  of DisappearPlace:
    node.solve(DisappearPlace, earlyStopping)
  of DisappearPlaceMore:
    node.solve(DisappearPlaceMore, earlyStopping)
  of DisappearConnect:
    node.solve(DisappearConnect, earlyStopping)
  of DisappearConnectMore:
    node.solve(DisappearConnectMore, earlyStopping)

# ------------------------------------------------
# Node <-> string
# ------------------------------------------------

const
  NodeStrSep = "<pon2-node-sep>"
  NodeStrAuxSep = "<pon2-node-aux-sep>"

func toStr(colors: set[ColorPuyo]): string {.inline.} =
  ## Returns the string representation of the colors.
  let strs = collect:
    for color in ColorPuyo.low..ColorPuyo.high:
      $(color in colors)

  result = strs.join NodeStrAuxSep

func toStr(moveResult: MoveResult): string {.inline.} =
  ## Returns the string representation of the move result.
  var strs = newSeq[string](0)

  strs.add $moveResult.chainCount

  strs.add $moveResult.totalDisappearCounts.isSome
  if moveResult.totalDisappearCounts.isSome:
    strs &= moveResult.totalDisappearCounts.get.mapIt $it

  strs.add $moveResult.disappearCounts.isSome
  if moveResult.disappearCounts.isSome:
    strs.add $moveResult.disappearCounts.get.len
    for counts in moveResult.disappearCounts.get:
      strs &= counts.mapIt $it

  strs.add $moveResult.detailDisappearCounts.isSome
  if moveResult.detailDisappearCounts.isSome:
    strs.add $moveResult.detailDisappearCounts.get.len
    for detailCounts in moveResult.detailDisappearCounts.get:
      for color in ColorPuyo.low..ColorPuyo.high:
        strs.add $detailCounts[color].len
        strs &= detailCounts[color].mapIt $it

  result = strs.join NodeStrAuxSep

func toStr*[F: TsuField or WaterField](node: Node[F]): string {.inline.} =
  ## Returns the string representation of the node.
  var strs = newSeqOfCap[string](17)

  strs.add $node.environment.toUri
  strs.add node.requirement.toUriQuery Izumiya

  strs.add $node.positions.toUriQuery Izumiya
  strs.add node.moveResult.toStr

  strs.add node.disappearedColors.toStr
  strs.add $node.disappearedCount

  for color in ColorPuyo.low..ColorPuyo.high:
    strs.add $node.fieldCounts[color]
  for color in ColorPuyo.low..ColorPuyo.high:
    strs.add $node.pairsCounts[color]
  strs.add $node.garbageCount

  result = strs.join NodeStrSep

func parseColors(str: string): set[ColorPuyo] {.inline.} =
  ## Converts the string to the colors.
  ## If the conversion fails, `ValueError` will be raised.
  result = {}
  for i, boolVal in str.split(NodeStrAuxSep).mapIt it.parseBool:
    result[ColorPuyo.low.succ i] = boolVal

func parseMoveResult(str: string): MoveResult {.inline.} =
  ## Converts the string to the move result.
  ## If the conversion fails, `ValueError` will be raised.
  let strs = str.split NodeStrAuxSep
  var idx = 0

  result.chainCount = strs[idx].parseInt
  idx.inc

  if strs[idx].parseBool:
    idx.inc
    result.totalDisappearCounts = some [0, 0, 0, 0, 0, 0, 0]
    for puyo in Puyo.low..Puyo.high:
      result.totalDisappearCounts.get[puyo] = strs[idx].parseInt
      idx.inc
  else:
    result.totalDisappearCounts = none array[Puyo, int]
    idx.inc

  if strs[idx].parseBool:
    idx.inc
    result.disappearCounts = some newSeq[array[Puyo, int]](strs[idx].parseInt)
    idx.inc

    for counts in result.disappearCounts.get.mitems:
      for puyo in Puyo.low..Puyo.high:
        counts[puyo] = strs[idx].parseInt
        idx.inc
  else:
    result.disappearCounts = none seq[array[Puyo, int]]
    idx.inc

  if strs[idx].parseBool:
    idx.inc
    result.detailDisappearCounts =
      some newSeq[array[ColorPuyo, seq[int]]](strs[idx].parseInt)
    idx.inc

    for detailCounts in result.detailDisappearCounts.get.mitems:
      for color in ColorPuyo.low..ColorPuyo.high:
        detailCounts[color] = newSeq[int](strs[idx].parseInt)
        idx.inc

        for count in detailCounts[color].mitems:
          count = strs[idx].parseInt
          idx.inc
  else:
    result.detailDisappearCounts = none seq[array[ColorPuyo, seq[int]]]

func parseNode*[F: TsuField or WaterField](str: string): Node[F] {.inline.} =
  ## Converts the string to the node.
  ## If the conversion fails, `ValueError` will be raised.
  let strs = str.split NodeStrSep

  result.environment = strs[0].parseUri.parseEnvironment[:F].environment
  result.requirement = strs[1].parseRequirement Izumiya

  result.positions = strs[2].parsePositions Izumiya
  result.moveResult = strs[3].parseMoveResult

  result.disappearedColors = strs[4].parseColors
  result.disappearedCount = strs[5].parseInt

  var idx = 6
  for color in ColorPuyo.low..ColorPuyo.high:
    result.fieldCounts[color] = strs[idx].parseInt
    idx.inc
  for color in ColorPuyo.low..ColorPuyo.high:
    result.pairsCounts[color] = strs[idx].parseInt
    idx.inc
  result.garbageCount = strs[16].parseInt