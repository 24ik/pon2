## This module implements solvers.
##

{.experimental: "strictDefs".}

import std/[options, sequtils, tables]
import ./[nazopuyo]
import ../corepkg/[cell, environment, field, moveresult, pair, position]
import ../private/[misc]
import ../private/nazopuyo/[mark]

when not defined(js):
  import std/[cpuinfo, os, threadpool]
  import suru

type Node[F: TsuField or WaterField] = object
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

func initNode[F: TsuField or WaterField](nazo: NazoPuyo[F]): Node[F]
             {.inline.} =
  ## Constructor of `Node`.
  result.environment = nazo.environment
  result.requirement = nazo.requirement

  result.positions = newSeqOfCap[Option[Position]] nazo.moveCount
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

func colorCount[F: TsuField or WaterField](node: Node[F], color: ColorPuyo): int
               {.inline.} =
  ## Returns the number of `color` puyos that do not disappear yet
  node.fieldCounts[color] + node.pairsCounts[color]

func isLeaf[F: TsuField or WaterField](node: Node[F]): bool {.inline.} =
  ## Returns `true` if the node is a leaf; *i.e.*, all moves are completed.
  node.environment.pairs.len == 0

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

func children[F: TsuField or WaterField](
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
      fieldCount = node.fieldCounts.sum + node.garbageCount
    elif reqColor == RequirementColor.Color:
      fieldCount = node.fieldCounts.sum
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

func canPrune[F: TsuField or WaterField](
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
        node.colorCount(it).filter4).sum

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
      sum (ColorPuyo.low..ColorPuyo.high).mapIt node.colorCount(it) div 4
    result = possibleChain < node.requirement.number.get
  elif reqKind in {DisappearColorSametime, DisappearColorMoreSametime}:
    let possibleColorCount =
      (ColorPuyo.low..ColorPuyo.high).countIt node.colorCount(it) >= 4
    result = possibleColorCount < node.requirement.number.get
  elif reqKind in {DisappearPlace, DisappearPlaceMore}:
    let possiblePlace: int
    when reqColor in {RequirementColor.All, RequirementColor.Color}:
      possiblePlace =
        sum (ColorPuyo.low..ColorPuyo.high).mapIt (node.colorCount(it) div 4)
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

const
  SuruBarUpdateMs = 100
  ParallelSolvingWaitIntervalMs = 100

func solveRec[F: TsuField or WaterField](
    node: Node[F], reqKind: static RequirementKind,
    reqColor: static RequirementColor): seq[Positions] {.inline.} =
  ## Solves the nazo puyo.
  ## `node` need to have a non-empty pairs.
  assert node.environment.pairs.len > 0

  result = @[]
  for child in node.children(reqKind, reqColor):
    if child.isAccepted(reqKind, reqColor):
      result &= child.positions
      continue

    if child.isLeaf or child.canPrune(reqKind, reqColor):
      continue

    result &= child.solveRec(reqKind, reqColor)

proc solve[F: TsuField or WaterField](
    nazo: NazoPuyo[F], reqKind: static RequirementKind,
    reqColor: static RequirementColor, parallelCount: Positive,
    showProgress: bool, earlyStopping: static bool): seq[Positions] {.inline.} =
  ## Solves the nazo puyo.
  ## `parallelCount` and `showProgress` will be ignored on JS backend.
  if not nazo.requirement.isSupported or nazo.moveCount == 0:
    return @[]

  let rootNode = nazo.initNode
  if rootNode.canPrune(reqKind, reqColor, true):
    return @[]

  result = @[]
  let childNodes = rootNode.children(reqKind, reqColor)
  when defined(js):
    for child in childNodes:
      result &= child.solveRec(reqKind, reqColor)

      when earlyStopping:
        if result.len > 1:
          return
  else:
    # set up the progress bar
    var bar: SuruBar
    if showProgress:
      bar = initSuruBar()
      bar[0].total = childNodes.len
      bar.setup

    # need branching if moveCount == 1 due to the limitation of `solveRec`
    if nazo.moveCount == 1:
      for child in childNodes:
        if child.isAccepted(reqKind, reqColor):
          result.add child.positions

        bar.inc
        bar.update SuruBarUpdateMs * 1000 * 1000

      if showProgress:
        bar.finish
      return

    # prepare solving
    let parallelCount2 = min(parallelCount, childNodes.len)
    var
      futureAnswers = newSeqOfCap[FlowVar[seq[Positions]]] childNodes.len
      nextNodeIdx = 0'i16
      runningNodeIdxes = newSeq[int16] parallelCount2
      completeNodeIdxes: set[int16] = {}

    # run "first wave" solving
    {.push warning[Effect]: off.}
    for parallelIdx in 0..<parallelCount2:
      futureAnswers.add spawn childNodes[nextNodeIdx].solveRec(
        reqKind, reqColor)
      runningNodeIdxes[parallelIdx] = nextNodeIdx
      nextNodeIdx.inc
    {.pop.}

    # solve
    while true:
      for parallelIdx in 0..<parallelCount2:
        # check if solving finished
        let nodeIdx = runningNodeIdxes[parallelIdx]
        if not futureAnswers[nodeIdx].isReady:
          continue

        # skip if the solution is already registered
        if nodeIdx in completeNodeIdxes:
          continue

        # update progress bar
        bar.inc
        bar.update SuruBarUpdateMs * 1000 * 1000

        completeNodeIdxes.incl nodeIdx
        result &= ^futureAnswers[nodeIdx]

        # finish solving
        if completeNodeIdxes.card == childNodes.len:
          if showProgress:
            bar.finish
          return

        # early stopping
        when earlyStopping:
          if result.len > 1:
            if showProgress:
              bar.finish
            return

        # assign the next node to the processor
        if nextNodeIdx < childNodes.len:
          futureAnswers.add spawn childNodes[nextNodeIdx].solveRec(
            reqKind, reqColor)
          runningNodeIdxes[parallelIdx] = nextNodeIdx
          nextNodeIdx.inc

      sleep ParallelSolvingWaitIntervalMs

proc solve[F: TsuField or WaterField](
    nazo: NazoPuyo[F], reqKind: static RequirementKind,
    parallelCount: Positive, showProgress: bool,
    earlyStopping: static bool): seq[Positions] {.inline.} =
  ## Solves the nazo puyo.
  ## `parallelCount` and `showProgress` will be ignored on JS backend.
  assert reqKind in {
    Clear, DisappearCount, DisappearCountMore, ChainClear, ChainMoreClear,
    DisappearCountSametime, DisappearCountMoreSametime, DisappearPlace,
    DisappearPlaceMore, DisappearConnect, DisappearConnectMore}

  case nazo.requirement.color.get
  of RequirementColor.All:
    nazo.solve(reqKind, RequirementColor.All, parallelCount, showProgress,
               earlyStopping)
  of RequirementColor.Red:
    nazo.solve(reqKind, RequirementColor.Red, parallelCount, showProgress,
               earlyStopping)
  of RequirementColor.Green:
    nazo.solve(reqKind, RequirementColor.Green, parallelCount, showProgress,
               earlyStopping)
  of RequirementColor.Blue:
    nazo.solve(reqKind, RequirementColor.Blue, parallelCount, showProgress,
               earlyStopping)
  of RequirementColor.Yellow:
    nazo.solve(reqKind, RequirementColor.Yellow, parallelCount, showProgress,
               earlyStopping)
  of RequirementColor.Purple:
    nazo.solve(reqKind, RequirementColor.Purple, parallelCount, showProgress,
               earlyStopping)
  of RequirementColor.Garbage:
    nazo.solve(reqKind, RequirementColor.Garbage, parallelCount, showProgress,
               earlyStopping)
  of RequirementColor.Color:
    nazo.solve(reqKind, RequirementColor.Color, parallelCount, showProgress,
               earlyStopping)
  
proc solve*[F: TsuField or WaterField](
    nazo: NazoPuyo[F],
    parallelCount: Positive = (
      when defined(js): 1 else: max(countProcessors(), 1)),
    showProgress = false, earlyStopping: static bool = false): seq[Positions]
    {.inline.} =
  ## Solves the nazo puyo.
  ## `parallelCount` and `showProgress` will be ignored on JS backend.
  const DummyColor = RequirementColor.All

  case nazo.requirement.kind
  of Clear:
    nazo.solve(Clear, parallelCount, showProgress, earlyStopping)
  of DisappearColor:
    nazo.solve(DisappearColor, DummyColor, parallelCount, showProgress,
               earlyStopping)
  of DisappearColorMore:
    nazo.solve(DisappearColorMore, DummyColor, parallelCount, showProgress,
               earlyStopping)
  of DisappearCount:
    nazo.solve(DisappearCount, parallelCount, showProgress, earlyStopping)
  of DisappearCountMore:
    nazo.solve(DisappearCountMore, parallelCount, showProgress, earlyStopping)
  of Chain:
    nazo.solve(Chain, DummyColor, parallelCount, showProgress, earlyStopping)
  of ChainMore:
    nazo.solve(ChainMore, DummyColor, parallelCount, showProgress,
               earlyStopping)
  of ChainClear:
    nazo.solve(ChainClear, parallelCount, showProgress, earlyStopping)
  of ChainMoreClear:
    nazo.solve(ChainMoreClear, parallelCount, showProgress, earlyStopping)
  of DisappearColorSametime:
    nazo.solve(DisappearColorSametime, DummyColor, parallelCount, showProgress,
               earlyStopping)
  of DisappearColorMoreSametime:
    nazo.solve(DisappearColorMoreSametime, DummyColor, parallelCount,
               showProgress, earlyStopping)
  of DisappearCountSametime:
    nazo.solve(DisappearCountSametime, parallelCount, showProgress,
               earlyStopping)
  of DisappearCountMoreSametime:
    nazo.solve(DisappearCountMoreSametime, parallelCount, showProgress,
               earlyStopping)
  of DisappearPlace:
    nazo.solve(DisappearPlace, parallelCount, showProgress, earlyStopping)
  of DisappearPlaceMore:
    nazo.solve(DisappearPlaceMore, parallelCount, showProgress, earlyStopping)
  of DisappearConnect:
    nazo.solve(DisappearConnect, parallelCount, showProgress, earlyStopping)
  of DisappearConnectMore:
    nazo.solve(DisappearConnectMore, parallelCount, showProgress, earlyStopping)
