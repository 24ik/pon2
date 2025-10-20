## This module implements nodes of solution search tree.
##
# NOTE: this is deprecated; removed after new implementation is completed.

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[deques, options, sequtils, setutils, strutils, sugar, tables, uri]
import ../[misc]
import ../core/[mark]
import
  ../../core/[
    cell, field, fqdn, moveresult, nazopuyo, pair, pairposition, position, puyopuyo,
    requirement,
  ]

type
  SolveAnswer* = Deque[Position] ## Nazo Puyo answer.

  Node*[F: TsuField or WaterField] = object ## Node of solution search tree.
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
  result = Node[F](
    nazoPuyo: nazo,
    moveResult: initMoveResult(0, [0, 0, 0, 0, 0, 0, 0]),
    disappearedColors: {},
    disappearedCount: 0,
    fieldCounts: [0, 0, 0, 0, 0],
    pairsCounts: [0, 0, 0, 0, 0],
    garbageCount: nazo.puyoPuyo.field.garbageCount,
  )

  for color in ColorPuyo:
    result.fieldCounts[color] = nazo.puyoPuyo.field.puyoCount color
    result.pairsCounts[color] = nazo.puyoPuyo.pairsPositions.puyoCount color

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

    let movePair = node.nazoPuyo.puyoPuyo.pairsPositions.peekFirst.pair
    result.pairsCounts[movePair.axis].dec
    result.pairsCounts[movePair.child].dec

  # update garbageCount
  when reqKind in {
    Clear, DisappearCount, DisappearCountMore, ChainClear, ChainMoreClear,
    DisappearCountSametime, DisappearCountMoreSametime,
  }:
    when reqColor in {RequirementColor.All, RequirementColor.Garbage}:
      result.garbageCount.dec result.moveResult.garbageCount

func children*[F: TsuField or WaterField](
    node: Node[F], reqKind: static RequirementKind, reqColor: static RequirementColor
): seq[tuple[node: Node[F], position: Position]] {.inline.} =
  ## Returns the children of the node.
  let positions =
    if node.nazoPuyo.puyoPuyo.pairsPositions.peekFirst.pair.isDouble:
      node.nazoPuyo.puyoPuyo.field.validDoublePositions
    else:
      node.nazoPuyo.puyoPuyo.field.validPositions

  result = positions.mapIt (node: node.child(it, reqKind, reqColor), position: it)

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

func solve[F: TsuField or WaterField](
    node: Node[F],
    results: var seq[SolveAnswer],
    moveCount: Positive,
    reqKind: static RequirementKind,
    reqColor: static RequirementColor,
    earlyStopping: static bool,
) {.inline.} =
  ## Solves the nazo puyo.
  ## Results are stored in `results`.
  if node.isAccepted(reqKind, reqColor):
    {.push warning[Uninit]: off.}
    results.add initDeque[Position](moveCount)
    {.pop.}
    return
  if node.isLeaf or node.canPrune(reqKind, reqColor):
    return

  for (child, pos) in node.children(reqKind, reqColor):
    var childResults = newSeq[Deque[Position]](0)
    child.solve childResults, moveCount, reqKind, reqColor, earlyStopping

    for res in childResults.mitems:
      res.addFirst pos

    results &= childResults

    when earlyStopping:
      if results.len > 1:
        return

func solve*[F: TsuField or WaterField](
    node: Node[F],
    moveCount: Positive,
    reqKind: static RequirementKind,
    reqColor: static RequirementColor,
    earlyStopping: static bool,
): seq[SolveAnswer] {.inline.} =
  ## Solves the nazo puyo.
  result = newSeq[Deque[Position]](0)
  node.solve result, moveCount, reqKind, reqColor, earlyStopping

func solve[F: TsuField or WaterField](
    node: Node[F],
    results: var seq[SolveAnswer],
    moveCount: Positive,
    reqKind: static RequirementKind,
    earlyStopping: static bool,
) {.inline.} =
  ## Solves the nazo puyo.
  ## Results are stored in `results`.
  assert reqKind in {
    RequirementKind.Clear, DisappearCount, DisappearCountMore, ChainClear,
    ChainMoreClear, DisappearCountSametime, DisappearCountMoreSametime, DisappearPlace,
    DisappearPlaceMore, DisappearConnect, DisappearConnectMore,
  }

  case node.nazoPuyo.requirement.color
  of RequirementColor.All:
    node.solve results, moveCount, reqKind, RequirementColor.All, earlyStopping
  of RequirementColor.Red:
    node.solve results, moveCount, reqKind, RequirementColor.Red, earlyStopping
  of RequirementColor.Green:
    node.solve results, moveCount, reqKind, RequirementColor.Green, earlyStopping
  of RequirementColor.Blue:
    node.solve results, moveCount, reqKind, RequirementColor.Blue, earlyStopping
  of RequirementColor.Yellow:
    node.solve results, moveCount, reqKind, RequirementColor.Yellow, earlyStopping
  of RequirementColor.Purple:
    node.solve results, moveCount, reqKind, RequirementColor.Purple, earlyStopping
  of RequirementColor.Garbage:
    node.solve results, moveCount, reqKind, RequirementColor.Garbage, earlyStopping
  of RequirementColor.Color:
    node.solve results, moveCount, reqKind, RequirementColor.Color, earlyStopping

func solve[F: TsuField or WaterField](
    node: Node[F],
    results: var seq[SolveAnswer],
    moveCount: Positive,
    earlyStopping: static bool = false,
) {.inline.} =
  ## Solves the nazo puyo.
  ## Results are stored in `results`.
  const DummyColor = RequirementColor.All

  case node.nazoPuyo.requirement.kind
  of RequirementKind.Clear:
    node.solve results, moveCount, RequirementKind.Clear, earlyStopping
  of DisappearColor:
    node.solve results, moveCount, DisappearColor, DummyColor, earlyStopping
  of DisappearColorMore:
    node.solve results, moveCount, DisappearColorMore, DummyColor, earlyStopping
  of DisappearCount:
    node.solve results, moveCount, DisappearCount, earlyStopping
  of DisappearCountMore:
    node.solve results, moveCount, DisappearCountMore, earlyStopping
  of Chain:
    node.solve results, moveCount, Chain, DummyColor, earlyStopping
  of ChainMore:
    node.solve results, moveCount, ChainMore, DummyColor, earlyStopping
  of ChainClear:
    node.solve results, moveCount, ChainClear, earlyStopping
  of ChainMoreClear:
    node.solve results, moveCount, ChainMoreClear, earlyStopping
  of DisappearColorSametime:
    node.solve results, moveCount, DisappearColorSametime, DummyColor, earlyStopping
  of DisappearColorMoreSametime:
    node.solve results, moveCount, DisappearColorMoreSametime, DummyColor, earlyStopping
  of DisappearCountSametime:
    node.solve results, moveCount, DisappearCountSametime, earlyStopping
  of DisappearCountMoreSametime:
    node.solve results, moveCount, DisappearCountMoreSametime, earlyStopping
  of DisappearPlace:
    node.solve results, moveCount, DisappearPlace, earlyStopping
  of DisappearPlaceMore:
    node.solve results, moveCount, DisappearPlaceMore, earlyStopping
  of DisappearConnect:
    node.solve results, moveCount, DisappearConnect, earlyStopping
  of DisappearConnectMore:
    node.solve results, moveCount, DisappearConnectMore, earlyStopping

func solve*[F: TsuField or WaterField](
    node: Node[F], moveCount: Positive, earlyStopping: static bool = false
): seq[SolveAnswer] {.inline.} =
  ## Solves the nazo puyo.
  result = newSeq[Deque[Position]](0)
  node.solve result, moveCount, earlyStopping

# ------------------------------------------------
# Node <-> string
# ------------------------------------------------

const
  NodeStrSep = "<pon2-solve-node-sep>"
  NodeStrAuxSep = "<pon2-solve-node-aux-sep>"

func toStr(colors: set[ColorPuyo]): string {.inline.} =
  ## Returns the string representation of the colors.
  let strs = collect:
    for color in ColorPuyo.low .. ColorPuyo.high:
      $(color in colors)

  result = strs.join NodeStrAuxSep

func trackingLevel(moveResult: MoveResult): int {.inline.} =
  ## Returns the tracking level of the move result.
  result =
    if moveResult.fullDisappearCounts.isSome:
      2
    elif moveResult.detailDisappearCounts.isSome:
      1
    else:
      0

func toStr(moveResult: MoveResult): string {.inline.} =
  ## Returns the string representation of the move result.
  var strs = newSeq[string](0)

  strs.add $moveResult.chainCount
  strs &= moveResult.disappearCounts.mapIt $it
  let level = moveResult.trackingLevel
  strs.add $level

  if level > 0:
    strs.add $moveResult.detailDisappearCounts.get.len
    for counts in moveResult.detailDisappearCounts.get:
      strs &= counts.mapIt $it

    if level > 1:
      strs.add $moveResult.fullDisappearCounts.get.len
      for detailCounts in moveResult.fullDisappearCounts.get:
        for color in ColorPuyo.low .. ColorPuyo.high:
          strs.add $detailCounts[color].len
          strs &= detailCounts[color].mapIt $it

  result = strs.join NodeStrAuxSep

func toStr*[F: TsuField or WaterField](node: Node[F]): string {.inline.} =
  ## Returns the string representation of the node.
  var strs = newSeqOfCap[string](15)

  strs.add $node.nazoPuyo.toUriQuery
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

  let level: int
  const Zeros: array[Puyo, int] = [0, 0, 0, 0, 0, 0, 0]
  case strs[8].parseInt
  of 0:
    level = 0
    result = initMoveResult(0, Zeros)
  of 1:
    level = 1
    result = initMoveResult(0, Zeros, @[])
  of 2:
    level = 2
    result = initMoveResult(0, Zeros, @[], @[])
  else:
    level = 0 # HACK: dummy to compile
    result = initMoveResult(0, Zeros) # HACK: dummy to suppress warning
    assert false

  result.chainCount = strs[0].parseInt
  for i in 0 ..< 7:
    result.disappearCounts[Puyo.low.succ i] = strs[1 + i].parseInt

  if level > 0:
    result.detailDisappearCounts = some newSeq[array[Puyo, int]](strs[9].parseInt)

    var idx = 10
    for counts in result.detailDisappearCounts.get.mitems:
      for puyo in Puyo.low .. Puyo.high:
        counts[puyo] = strs[idx].parseInt
        idx.inc

    if level > 1:
      result.fullDisappearCounts =
        some newSeq[array[ColorPuyo, seq[int]]](strs[idx].parseInt)

      for detailCounts in result.fullDisappearCounts.get.mitems:
        for color in ColorPuyo.low .. ColorPuyo.high:
          detailCounts[color] = newSeq(strs[idx].parseInt)
          idx.inc

          for count in detailCounts[color].mitems:
            count = strs[idx].parseInt
            idx.inc

func parseNode*[F: TsuField or WaterField](str: string): Node[F] {.inline.} =
  ## Converts the string to the node.
  ## If the conversion fails, `ValueError` will be raised.
  let strs = str.split NodeStrSep

  result = initNode[F](parseNazoPuyo[F](strs[0], Pon2))
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
  result.garbageCount = strs[idx].parseInt
