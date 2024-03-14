## This module implements nodes of solution search tree.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, setutils, strutils, sugar, tables, uri]
import ../[misc]
import ../core/[mark]
import
  ../../core/[
    cell, field, host, moveresult, nazopuyo, pair, pairposition, position, puyopuyo,
    requirement,
  ]

type Node*[F: TsuField or WaterField] = object ## Node of solution search tree.
  nazoPuyo: NazoPuyo[F]
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

func initNode*[F: TsuField or WaterField](nazo: NazoPuyo[F]): Node[F] {.inline.} =
  ## Returns the root node of the nazo puyo.
  result.nazoPuyo = nazo
  result.moveResult = initMoveResult(0, [0, 0, 0, 0, 0, 0, 0])

  result.disappearedColors = {}
  result.disappearedCount = 0

  for color in ColorPuyo:
    result.fieldCounts[color] = nazo.puyoPuyo.field.puyoCount color
    result.pairsCounts[color] = nazo.puyoPuyo.pairsPositions.puyoCount color
  result.garbageCount = nazo.puyoPuyo.field.garbageCount

# ------------------------------------------------
# Property
# ------------------------------------------------

func colorCount[F: TsuField or WaterField](
    node: Node[F], color: ColorPuyo
): int {.inline.} =
  ## Returns the number of `color` puyos that do not disappear yet.
  node.fieldCounts[color] + node.pairsCounts[color]

func isLeaf[F: TsuField or WaterField](node: Node[F]): bool {.inline.} =
  ## Returns `true` if the node is a leaf.
  node.nazoPuyo.puyoPuyo.movingCompleted or node.nazoPuyo.puyoPuyo.field.isDead

# ------------------------------------------------
# Child
# ------------------------------------------------

const ReqColorToPuyo: array[RequirementColor, Puyo] = [
  Puyo.low, Cell.Red, Cell.Green, Cell.Blue, Cell.Yellow, Cell.Purple, Cell.Garbage,
  Puyo.low,
]

func child[F: TsuField or WaterField](
    node: Node[F],
    pos: Position,
    reqKind: static RequirementKind,
    reqColor: static RequirementColor,
): Node[F] {.inline.} =
  ## Returns the child node with the `pos` edge.
  when reqKind notin {DisappearColor, DisappearColorMore}:
    let putPair = node.nazoPuyo.puyoPuyo.nextPairPosition.pair

  result = node
  result.moveResult =
    when reqKind in {
      Clear, DisappearColor, DisappearColorMore, DisappearCount, DisappearCountMore,
      Chain, ChainMore, ChainClear, ChainMoreClear,
    }:
      result.nazoPuyo.puyoPuyo.move0 pos
    elif reqKind in {
      DisappearColorSametime, DisappearColorMoreSametime, DisappearCountSametime,
      DisappearCountMoreSametime,
    }:
      result.nazoPuyo.puyoPuyo.move1 pos
    else:
      result.nazoPuyo.puyoPuyo.move2 pos

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
      result.disappearedCount.inc result.moveResult.puyoCount ReqColorToPuyo[reqColor]

  # update fieldCounts, pairsCounts
  when reqKind notin {DisappearColor, DisappearColorMore}:
    when reqKind notin ColorKinds or
        reqColor in
        {RequirementColor.All, RequirementColor.Color, RequirementColor.Garbage}:
      for color in ColorPuyo:
        result.fieldCounts[color] = result.nazoPuyo.puyoPuyo.field.puyoCount color
    else:
      let puyo = ReqColorToPuyo[reqColor]
      result.fieldCounts[puyo] = result.nazoPuyo.puyoPuyo.field.puyoCount puyo

    result.pairsCounts[putPair.axis].dec
    result.pairsCounts[putPair.child].dec

  # update garbageCount
  when reqKind in {
    Clear, DisappearCount, DisappearCountMore, ChainClear, ChainMoreClear,
    DisappearCountSametime, DisappearCountMoreSametime,
  }:
    when reqColor in {RequirementColor.All, RequirementColor.Garbage}:
      result.garbageCount.dec result.moveResult.garbageCount

func children*[F: TsuField or WaterField](
    node: Node[F], reqKind: static RequirementKind, reqColor: static RequirementColor
): seq[Node[F]] {.inline.} =
  ## Returns the children of the node.
  let positions =
    if node.nazoPuyo.puyoPuyo.nextPairPosition.pair.isDouble:
      node.nazoPuyo.puyoPuyo.field.validDoublePositions
    else:
      node.nazoPuyo.puyoPuyo.field.validPositions

  result = positions.mapIt node.child(it, reqKind, reqColor)

# ------------------------------------------------
# Accept
# ------------------------------------------------

func isAccepted[F: TsuField or WaterField](
    node: Node[F], reqKind: static RequirementKind, reqColor: static RequirementColor
): bool {.inline.} =
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
    result =
      node.nazoPuyo.requirement.disappearColorSatisfied(node.disappearedColors, reqKind)
  elif reqKind in {DisappearCount, DisappearCountMore}:
    result =
      node.nazoPuyo.requirement.disappearCountSatisfied(node.disappearedCount, reqKind)
  elif reqKind in {Chain, ChainMore, ChainClear, ChainMoreClear}:
    result = node.nazoPuyo.requirement.chainSatisfied(node.moveResult, reqKind)
  elif reqKind in {DisappearColorSametime, DisappearColorMoreSametime}:
    result = node.nazoPuyo.requirement.disappearColorSametimeSatisfied(
      node.moveResult, reqKind
    )
  elif reqKind in {DisappearCountSametime, DisappearCountMoreSametime}:
    result = node.nazoPuyo.requirement.disappearCountSametimeSatisfied(
      node.moveResult, reqKind, reqColor
    )
  elif reqKind in {DisappearPlace, DisappearPlaceMore}:
    result = node.nazoPuyo.requirement.disappearPlaceSatisfied(
      node.moveResult, reqKind, reqColor
    )
  elif reqKind in {DisappearConnect, DisappearConnectMore}:
    result = node.nazoPuyo.requirement.disappearConnectSatisfied(
      node.moveResult, reqKind, reqColor
    )
  else:
    assert false

# ------------------------------------------------
# Prune
# ------------------------------------------------

func filter4[T: SomeNumber or Natural](x: T): T {.inline.} =
  ## If `x` is equal or greater than 4, returns `x`; otherwise returns 0.
  x * (x >= 4).T

func canPrune*[F: TsuField or WaterField](
    node: Node[F],
    reqKind: static RequirementKind,
    reqColor: static RequirementColor,
    firstCall: static bool = false,
): bool {.inline.} =
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

      canPrune =
        hasNotDisappearableColor or (
          node.garbageCount > 0 and not hasDisappearableColor
        )
    elif reqColor == RequirementColor.Color:
      canPrune = (ColorPuyo.low .. ColorPuyo.high).anyIt(
        node.fieldCounts[it] > 0 and node.colorCount(it) < 4
      )
    elif reqColor == RequirementColor.Garbage:
      canPrune =
        node.garbageCount > 0 and
        (ColorPuyo.low .. ColorPuyo.high).allIt node.colorCount(it) < 4
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
      result =
        (ColorPuyo.low .. ColorPuyo.high).countIt(node.colorCount(it) >= 4) <
        node.nazoPuyo.requirement.number
    else:
      result = false
  elif reqKind in {
    DisappearCount, DisappearCountMore, DisappearCountSametime,
    DisappearCountMoreSametime, DisappearConnect, DisappearConnectMore,
  }:
    let nowPossibleCount: int
    when reqColor in
        {RequirementColor.All, RequirementColor.Color, RequirementColor.Garbage}:
      let colorPossibleCount =
        (ColorPuyo.low .. ColorPuyo.high).mapIt(node.colorCount(it).filter4).sum2

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
      elif reqKind in {
        DisappearCountSametime, DisappearCountMoreSametime, DisappearConnect,
        DisappearConnectMore,
      }:
        nowPossibleCount
      else:
        assert false
        0

    result = possibleCount < node.nazoPuyo.requirement.number
  elif reqKind in {Chain, ChainMore, ChainClear, ChainMoreClear}:
    let possibleChain =
      sum2 (ColorPuyo.low .. ColorPuyo.high).mapIt node.colorCount(it) div 4
    result = possibleChain < node.nazoPuyo.requirement.number
  elif reqKind in {DisappearColorSametime, DisappearColorMoreSametime}:
    let possibleColorCount =
      (ColorPuyo.low .. ColorPuyo.high).countIt node.colorCount(it) >= 4
    result = possibleColorCount < node.nazoPuyo.requirement.number
  elif reqKind in {DisappearPlace, DisappearPlaceMore}:
    let possiblePlace: int
    when reqColor in {RequirementColor.All, RequirementColor.Color}:
      possiblePlace =
        sum2 (ColorPuyo.low .. ColorPuyo.high).mapIt (node.colorCount(it) div 4)
    elif reqColor == RequirementColor.Garbage:
      assert false
      possiblePlace = 0
    else:
      possiblePlace = node.colorCount(ReqColorToPuyo[reqColor]) div 4

    result = possiblePlace < node.nazoPuyo.requirement.number
  else:
    assert false

# ------------------------------------------------
# Solve
# ------------------------------------------------

func solve*[F: TsuField or WaterField](
    node: Node[F],
    reqKind: static RequirementKind,
    reqColor: static RequirementColor,
    earlyStopping: static bool,
): seq[PairsPositions] {.inline.} =
  ## Solves the nazo puyo.
  if node.isAccepted(reqKind, reqColor):
    return @[node.nazoPuyo.puyoPuyo.pairsPositions]
  if node.isLeaf or node.canPrune(reqKind, reqColor):
    return @[]

  result = @[]
  for child in node.children(reqKind, reqColor):
    result &= child.solve(reqKind, reqColor, earlyStopping)

    when earlyStopping:
      if result.len > 1:
        return

func solve[F: TsuField or WaterField](
    node: Node[F], reqKind: static RequirementKind, earlyStopping: static bool
): seq[PairsPositions] {.inline.} =
  ## Solves the nazo puyo.
  assert reqKind in {
    RequirementKind.Clear, DisappearCount, DisappearCountMore, ChainClear,
    ChainMoreClear, DisappearCountSametime, DisappearCountMoreSametime, DisappearPlace,
    DisappearPlaceMore, DisappearConnect, DisappearConnectMore,
  }

  result =
    case node.nazoPuyo.requirement.color
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
    node: Node[F], earlyStopping: static bool = false
): seq[PairsPositions] {.inline.} =
  ## Solves the nazo puyo.
  const DummyColor = RequirementColor.All

  result =
    case node.nazoPuyo.requirement.kind
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
    for color in ColorPuyo.low .. ColorPuyo.high:
      $(color in colors)

  result = strs.join NodeStrAuxSep

func toStr(moveResult: MoveResult): string {.inline.} =
  ## Returns the string representation of the move result.
  var strs = newSeq[string](0)

  strs.add $moveResult.chainCount
  strs &= moveResult.disappearCounts.mapIt $it
  strs.add $moveResult.trackingLevel.ord

  case moveResult.trackingLevel
  of Level0:
    discard
  of Level1:
    strs.add $moveResult.detailDisappearCounts.len
    for counts in moveResult.detailDisappearCounts:
      strs &= counts.mapIt $it
  of Level2:
    strs.add $moveResult.fullDisappearCounts.len
    for detailCounts in moveResult.fullDisappearCounts:
      for color in ColorPuyo.low .. ColorPuyo.high:
        strs.add $detailCounts[color].len
        strs &= detailCounts[color].mapIt $it

  result = strs.join NodeStrAuxSep

func toStr*[F: TsuField or WaterField](node: Node[F]): string {.inline.} =
  ## Returns the string representation of the node.
  var strs = newSeqOfCap[string](15)

  strs.add $node.nazoPuyo.toUriQuery Izumiya
  strs.add node.moveResult.toStr

  strs.add node.disappearedColors.toStr
  strs.add $node.disappearedCount

  for color in ColorPuyo.low .. ColorPuyo.high:
    strs.add $node.fieldCounts[color]
  for color in ColorPuyo.low .. ColorPuyo.high:
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

  const Zeros: array[Puyo, int] = [0, 0, 0, 0, 0, 0, 0]
  case strs[8].parseInt
  of 0:
    result = initMoveResult(0, Zeros)
  of 1:
    result = initMoveResult(0, Zeros, newSeq[array[Puyo, int]](0))
  of 2:
    result = initMoveResult(0, Zeros, newSeq[array[ColorPuyo, seq[int]]](0))
  else:
    raise newException(ValueError, "Invalid move result: " & str)

  result.chainCount = strs[0].parseInt
  for i in 0 ..< 7:
    result.disappearCounts[Puyo.low.succ i] = strs[1 + i].parseInt

  case result.trackingLevel
  of Level0:
    discard
  of Level1:
    result.detailDisappearCounts = newSeq[array[Puyo, int]](strs[10].parseInt)

    var idx = 11
    for counts in result.detailDisappearCounts.mitems:
      for puyo in Puyo.low .. Puyo.high:
        counts[puyo] = strs[idx].parseInt
        idx.inc
  of Level2:
    result.fullDisappearCounts = newSeq[array[ColorPuyo, seq[int]]](strs[10].parseInt)

    var idx = 11
    for detailCounts in result.fullDisappearCounts.mitems:
      for color in ColorPuyo.low .. ColorPuyo.high:
        detailCounts[color] = newSeq[int](strs[idx].parseInt)
        idx.inc

        for count in detailCounts[color].mitems:
          count = strs[idx].parseInt
          idx.inc

func parseNode*[F: TsuField or WaterField](str: string): Node[F] {.inline.} =
  ## Converts the string to the node.
  ## If the conversion fails, `ValueError` will be raised.
  let strs = str.split NodeStrSep

  result.nazoPuyo = parseNazoPuyo[F](strs[0], Izumiya)
  result.moveResult = strs[1].parseMoveResult

  result.disappearedColors = strs[2].parseColors
  result.disappearedCount = strs[3].parseInt

  var idx = 4
  for color in ColorPuyo.low .. ColorPuyo.high:
    result.fieldCounts[color] = strs[idx].parseInt
    idx.inc
  for color in ColorPuyo.low .. ColorPuyo.high:
    result.pairsCounts[color] = strs[idx].parseInt
    idx.inc
  result.garbageCount = strs[14].parseInt
