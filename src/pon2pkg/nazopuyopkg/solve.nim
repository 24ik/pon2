## This module implements solvers.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[options, sequtils, setutils, tables]
import ./[nazopuyo]
import ../corepkg/[cell, environment, field, moveresult, pair, position]
import ../private/[misc]
import ../private/nazopuyo/[mark]

{.push warning[Deprecated]: off.}
when not defined(js):
  import std/[os, threadpool]
  import suru
{.pop.}

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

func colorCount[F: TsuField or WaterField](node: Node[F], color: ColorPuyo): int
               {.inline.} =
  ## Returns the number of `color` puyos that do not disappear yet
  node.fieldCounts[color] + node.pairsCounts[color]

func depth[F: TsuField or WaterField](node: Node[F]): int {.inline.} =
  ## Returns the node's depth.
  ## Root's depth is zero.
  node.positions.len

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

const ParallelSolvingWaitIntervalMs = 8

func solve[F: TsuField or WaterField](
    node: Node[F], reqKind: static RequirementKind,
    reqColor: static RequirementColor, earlyStopping: static bool):
    seq[Positions] {.inline.} =
  ## Solves the nazo puyo.
  ## This version should be used in spawned threads or on JS backend.
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

when not defined(js):
  template monitor(futures: seq[FlowVar[seq[Positions]]],
                  solvingFutureIdxes: var set[int16],
                  solvedFutureIdxes: var set[int16],
                  answers: var seq[Positions], progressBar: var SuruBar) =
    ## Monitors the futures.
    # NOTE: we use template instead of proc to remove warning
    for futureIdx in solvingFutureIdxes:
      let solved = futures[futureIdx].isReady
      solvedFutureIdxes[futureIdx] = solved
      solvingFutureIdxes[futureIdx] = not solved

      if solved:
        answers &= ^futures[futureIdx]

        progressBar.inc
        progressBar.update

  proc setCompleted(progressBar: var SuruBar) {.inline.} =
    ## Sets the progress bar completed.
    progressBar.inc progressBar[0].total - progressBar[0].progress
    progressBar.update

  proc solve[F: TsuField or WaterField](
      node: Node[F], reqKind: static RequirementKind,
      reqColor: static RequirementColor, earlyStopping: static bool,
      spawnDepth: Natural, progressBar: var SuruBar,
      incValues: openArray[Natural]): seq[Positions] {.inline.} =
    ## Solves the nazo puyo.
    ## This version should be used on non-JS backend.
    if node.isAccepted(reqKind, reqColor):
      progressBar.inc incValues[node.depth]
      progressBar.update
      return @[node.positions]
    if node.isLeaf or node.canPrune(reqKind, reqColor):
      progressBar.inc incValues[node.depth]
      progressBar.update
      return @[]

    result = @[]
    let childNodes = node.children(reqKind, reqColor)
    if node.depth == spawnDepth:
      var
        futures = newSeqOfCap[FlowVar[seq[Positions]]](childNodes.len)
        nextChildIdx = 0'i16
        solvingFutureIdxes: set[int16] = {}
        solvedFutureIdxes: set[int16] = {}
      while nextChildIdx < childNodes.len.int16:
        if preferSpawn():
          {.push warning[Effect]: off.}
          futures.add spawn childNodes[nextChildIdx].solve(
            reqKind, reqColor, earlyStopping)
          solvingFutureIdxes.incl nextChildIdx
          nextChildIdx.inc
          {.pop.}
        else:
          futures.monitor solvingFutureIdxes, solvedFutureIdxes, result,
            progressBar
          sleep ParallelSolvingWaitIntervalMs

          when earlyStopping:
            if result.len > 1:
              progressBar.setCompleted
              return

      while solvedFutureIdxes.card < childNodes.len:
        futures.monitor solvingFutureIdxes, solvedFutureIdxes, result, progressBar
        sleep ParallelSolvingWaitIntervalMs

        when earlyStopping:
          if result.len > 1:
            progressBar.setCompleted
            return
    else:
      for child in childNodes:
        result &= child.solve(reqKind, reqColor, earlyStopping, spawnDepth,
                              progressBar, incValues)

        when earlyStopping:
          if result.len > 1:
            progressBar.setCompleted
            return

proc solve[F: TsuField or WaterField](
    nazo: NazoPuyo[F], reqKind: static RequirementKind,
    reqColor: static RequirementColor, showProgress: bool,
    earlyStopping: static bool): seq[Positions] {.inline.} =
  ## Solves the nazo puyo.
  ## `showProgress` will be ignored on JS backend.
  if not nazo.requirement.isSupported or nazo.moveCount == 0:
    return @[]

  let rootNode = nazo.initNode
  when defined(js):
    result = @[]
    for child in rootNode.children(reqKind, reqColor):
      result &= child.solve(reqKind, reqColor, earlyStopping)

      when earlyStopping:
        if result.len > 1:
          return
  else:
    let spawnDepth = max(nazo.moveCount - 7, 0) # determined experimentally

    var incValues = 0.Natural.repeat spawnDepth.succ 2
    incValues[^1] = 1 # HACK: this is dummy to simplify the code
    for depth in countdown(spawnDepth, 0):
      incValues[depth] = incValues[depth.succ] * (
        if nazo.environment.pairs[depth].isDouble: DoublePositions.card
        else: AllPositions.card)

    var progressBar: SuruBar
    if showProgress:
      progressBar = initSuruBar()
      progressBar[0].total = incValues[0]
      progressBar.setup

    result = rootNode.solve(reqKind, reqColor, earlyStopping, spawnDepth,
                            progressBar, incValues)

    if showProgress:
      progressBar.finish

proc solve[F: TsuField or WaterField](
    nazo: NazoPuyo[F], reqKind: static RequirementKind, showProgress: bool,
    earlyStopping: static bool): seq[Positions] {.inline.} =
  ## Solves the nazo puyo.
  ## `showProgress` will be ignored on JS backend.
  assert reqKind in {
    Clear, DisappearCount, DisappearCountMore, ChainClear, ChainMoreClear,
    DisappearCountSametime, DisappearCountMoreSametime, DisappearPlace,
    DisappearPlaceMore, DisappearConnect, DisappearConnectMore}

  case nazo.requirement.color.get
  of RequirementColor.All:
    nazo.solve(reqKind, RequirementColor.All, showProgress, earlyStopping)
  of RequirementColor.Red:
    nazo.solve(reqKind, RequirementColor.Red, showProgress, earlyStopping)
  of RequirementColor.Green:
    nazo.solve(reqKind, RequirementColor.Green, showProgress, earlyStopping)
  of RequirementColor.Blue:
    nazo.solve(reqKind, RequirementColor.Blue, showProgress, earlyStopping)
  of RequirementColor.Yellow:
    nazo.solve(reqKind, RequirementColor.Yellow, showProgress, earlyStopping)
  of RequirementColor.Purple:
    nazo.solve(reqKind, RequirementColor.Purple, showProgress, earlyStopping)
  of RequirementColor.Garbage:
    nazo.solve(reqKind, RequirementColor.Garbage, showProgress, earlyStopping)
  of RequirementColor.Color:
    nazo.solve(reqKind, RequirementColor.Color, showProgress, earlyStopping)

proc solve*[F: TsuField or WaterField](
    nazo: NazoPuyo[F], showProgress = false,
    earlyStopping: static bool = false): seq[Positions] {.inline.} =
  ## Solves the nazo puyo.
  ## `showProgress` will be ignored on JS backend.
  const DummyColor = RequirementColor.All

  case nazo.requirement.kind
  of Clear:
    nazo.solve(Clear, showProgress, earlyStopping)
  of DisappearColor:
    nazo.solve(DisappearColor, DummyColor, showProgress, earlyStopping)
  of DisappearColorMore:
    nazo.solve(DisappearColorMore, DummyColor, showProgress, earlyStopping)
  of DisappearCount:
    nazo.solve(DisappearCount, showProgress, earlyStopping)
  of DisappearCountMore:
    nazo.solve(DisappearCountMore, showProgress, earlyStopping)
  of Chain:
    nazo.solve(Chain, DummyColor, showProgress, earlyStopping)
  of ChainMore:
    nazo.solve(ChainMore, DummyColor, showProgress, earlyStopping)
  of ChainClear:
    nazo.solve(ChainClear, showProgress, earlyStopping)
  of ChainMoreClear:
    nazo.solve(ChainMoreClear, showProgress, earlyStopping)
  of DisappearColorSametime:
    nazo.solve(DisappearColorSametime, DummyColor, showProgress, earlyStopping)
  of DisappearColorMoreSametime:
    nazo.solve(DisappearColorMoreSametime, DummyColor, showProgress,
               earlyStopping)
  of DisappearCountSametime:
    nazo.solve(DisappearCountSametime, showProgress, earlyStopping)
  of DisappearCountMoreSametime:
    nazo.solve(DisappearCountMoreSametime, showProgress, earlyStopping)
  of DisappearPlace:
    nazo.solve(DisappearPlace, showProgress, earlyStopping)
  of DisappearPlaceMore:
    nazo.solve(DisappearPlaceMore, showProgress, earlyStopping)
  of DisappearConnect:
    nazo.solve(DisappearConnect, showProgress, earlyStopping)
  of DisappearConnectMore:
    nazo.solve(DisappearConnectMore, showProgress, earlyStopping)
