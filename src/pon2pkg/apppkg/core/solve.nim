## This module implements solvers.
##

{.experimental: "strictDefs".}

import std/[math, options, sequtils, setutils, sugar, tables]
import ../../corepkg/[cell, field, environment, moveresult, position]
import ../../nazopuyopkg/[nazopuyo]

when not defined(js):
  import std/[cpuinfo, os, threadpool]
  import suru

type
  Node[F: TsuField or WaterField] = tuple
    ## Node of solution search tree.
    nazo: NazoPuyo[F]
    positions: Positions

    isChainKind: bool
    isExactKind: bool

    # used to check if the requirement are satisfied
    disappearColors: Option[set[ColorPuyo]]
    number: Option[Natural]
    numbers: Option[seq[int]]

    # used to check if the field is cleared
    fieldCount: Option[Natural]

    # used to calculate the maximum number of puyoes that can disappear
    puyoCount: Option[Natural]
    puyoCounts: Option[array[Puyo, Natural]]

  InspectAnswers* = tuple
    ## Sequence of Nazo Puyo answers with the number of search tree nodes
    ## visited.
    answers: seq[Positions]
    visitNodeCount: Positive

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const RequirementColorToCell = {
  RequirementColor.Garbage: Cell.Garbage,
  RequirementColor.Red: Cell.Red,
  RequirementColor.Green: Cell.Green,
  RequirementColor.Blue: Cell.Blue,
  RequirementColor.Yellow: Cell.Yellow,
  RequirementColor.Purple: Cell.Purple}.toTable

func initNode(nazo: NazoPuyo): Node {.inline.} =
  ## Converts the nazo puyo to the node.
  result.nazo = nazo
  result.positions = newSeqOfCap[Option[Position]] nazo.moveCount

  # kinds
  result.isChainKind =
    nazo.requirement.kind in {Chain, ChainMore, ChainClear, ChainMoreClear}
  result.isExactKind = nazo.requirement.kind in {
    DisappearColor, DIsappearCount, Chain, ChainClear, DisappearColorSametime,
    DisappearCountSametime, DisappearPlace, DisappearConnect}

  # set property corresponding to 'n' in the kind
  case nazo.requirement.kind
  of Clear:
    discard
  of DisappearColor, DisappearColorMore:
    result.disappearColors = some set[ColorPuyo]({})
  of DisappearCount, DisappearCountMore, Chain, ChainMore, ChainClear,
      ChainMoreClear:
    result.number = some 0.Natural
  else:
    result.numbers = some newSeq[int] 0

  # number of puyoes in the field
  if nazo.requirement.kind in {Clear, ChainClear, ChainMoreClear}:
    case nazo.requirement.color.get
    of RequirementColor.All:
      result.fieldCount = some nazo.environment.field.countPuyo.Natural
    of RequirementColor.Color:
      result.fieldCount = some nazo.environment.field.countColor.Natural
    of RequirementColor.Garbage:
      result.fieldCount = some nazo.environment.field.countGarbage.Natural
    else:
      result.fieldCount = some Natural nazo.environment.field.count(
        RequirementColorToCell[nazo.requirement.color.get])

  # number of puyoes that can disappear
  if (
      result.isChainKind or
      nazo.requirement.kind in NoColorKinds or
      nazo.requirement.color.get in {
        RequirementColor.All, RequirementColor.Garbage,
        RequirementColor.Color}):
    var puyoCounts: array[Puyo, Natural]
    puyoCounts[Cell.Garbage] = nazo.environment.countGarbage
    for color in ColorPuyo:
      puyoCounts[color] = Natural nazo.environment.count color
    result.puyoCounts = some puyoCounts
  else:
    result.puyoCount = some Natural nazo.environment.count(
      RequirementColorToCell[nazo.requirement.color.get])

# ------------------------------------------------
# Prune
# ------------------------------------------------

func filter4(num: int): int {.inline.} = num * (num >= 4).int
  ## If `num >= 4`, returns `num`.
  ## Otherwise, returns `0`.

func canPrune(node: Node): bool {.inline.} =
  ## Returns `true` if the `node` is in the unsolvable state.
  if node.nazo.environment.field.isDead:
    return true

  # check if it is impossible to clear the field
  if node.fieldCount.isSome:
    if node.puyoCount.isSome:
      if node.puyoCount.get in 1..3:
        return true
    else:
      if node.puyoCounts.get[ColorPuyo.low..ColorPuyo.high].anyIt it in 1..3:
        return true

  # check the number corresponding to 'n' in the kind
  var
    nowNum = 0
    possibleNum = 0
    targetNum =
      if node.nazo.requirement.number.isSome:
        node.nazo.requirement.number.get.int
      else: -1
  case node.nazo.requirement.kind
  of Clear:
    discard
  of DisappearColor, DisappearColorMore, DisappearColorSametime,
      DisappearColorMoreSametime:
    if node.nazo.requirement.kind in {DisappearColor, DisappearColorMore}:
      nowNum = node.disappearColors.get.card

    possibleNum =
      node.puyoCounts.get[ColorPuyo.low..ColorPuyo.high].countIt it >= 4
  of DisappearCount, DisappearCountMore, DisappearCountSametime,
      DisappearCountMoreSametime:
    if node.nazo.requirement.kind in {DisappearCount, DisappearCountMore}:
      nowNum = node.number.get

    if node.puyoCount.isSome:
      possibleNum = node.puyoCount.get.filter4
    else:
      let colorPossibleNum =
        sum node.puyoCounts.get[ColorPuyo.low..ColorPuyo.high].mapIt it.filter4
      if node.nazo.requirement.color.get in {
          RequirementColor.All, RequirementColor.Color}:
        possibleNum = colorPossibleNum
      if node.nazo.requirement.color.get in {
          RequirementColor.All, RequirementColor.Garbage}:
        if colorPossibleNum > 0:
          possibleNum.inc node.puyoCounts.get[Cell.Garbage]
  of Chain, ChainMore, ChainClear, ChainMoreClear:
    possibleNum =
      sum node.puyoCounts.get[ColorPuyo.low..ColorPuyo.high].mapIt it div 4
  of DisappearPlace, DisappearPlaceMore:
    if node.puyoCount.isSome:
      possibleNum = node.puyoCount.get div 4
    else:
      possibleNum =
        sum node.puyoCounts.get[ColorPuyo.low..ColorPuyo.high].mapIt it div 4
  of DisappearConnect, DisappearConnectMore:
    if node.puyoCount.isSome:
      possibleNum = node.puyoCount.get.filter4
    else:
      possibleNum =
        max node.puyoCounts.get[ColorPuyo.low..ColorPuyo.high].mapIt it.filter4

  if nowNum + possibleNum < targetNum:
    return true

# ------------------------------------------------
# Search Tree Operation
# ------------------------------------------------

func isLeaf(node: Node): bool {.inline.} =
  ## Returns `true` if the node is the leaf; *i.e.*, all moves are completed.
  node.positions.len == node.nazo.moveCount

func child(node: Node, pos: Position): Node {.inline.} =
  ## Returns the child of the `node` with the `pos` edge.
  let moveFn = case node.nazo.requirement.kind
  of Clear, DisappearColor, DisappearColorMore, DisappearCount,
      DisappearCountMore, Chain, ChainMore, ChainClear, ChainMoreClear:
    environment.moveWithRoughTracking
  of DisappearColorSametime, DisappearColorMoreSametime, DisappearCountSametime,
      DisappearCountMoreSametime:
    environment.moveWithDetailTracking
  else:
    environment.moveWithFullTracking
  
  result = node
  result.positions.add pos.some

  let
    pair = result.nazo.environment.pairs.peekFirst
    moveResult = result.nazo.environment.moveFn pos

  # set the number corresponding to 'n' in the kind
  case node.nazo.requirement.kind
  of Clear:
    discard
  of DisappearColor, DisappearColorMore:
    var colors = node.disappearColors.get
    for color in ColorPuyo:
      if moveResult.totalDisappearCounts[color] > 0:
        colors.incl color
    result.disappearColors = some colors
  of DisappearCount, DisappearCountMore:
    result.number = some node.number.get.succ(
      case node.nazo.requirement.color.get
      of RequirementColor.All: moveResult.puyoCount
      of RequirementColor.Color: moveResult.colorCount
      else: moveResult.totalDisappearCounts[
        RequirementColorToCell[node.nazo.requirement.color.get]]
    )
  of Chain, ChainMore, ChainClear, ChainMoreClear:
    result.number = some moveResult.chainCount
  of DisappearColorSametime, DisappearColorMoreSametime:
    let numbers = collect:
      for countsArray in moveResult.disappearCounts:
        countsArray[ColorPuyo.low..ColorPuyo.high].countIt it > 0
    result.numbers = some numbers
  of DisappearCountSametime, DisappearCountMoreSametime:
    let nums = case node.nazo.requirement.color.get
    of RequirementColor.All: moveResult.puyoCounts
    of RequirementColor.Color: moveResult.colorCounts
    else: moveResult.disappearCounts.mapIt it[
      RequirementColorToCell[node.nazo.requirement.color.get]].int
    result.numbers = some nums
  of DisappearPlace, DisappearPlaceMore:
    var nums = newSeq[int](0)
    case node.nazo.requirement.color.get
    of RequirementColor.All, RequirementColor.Color:
      for countsArray in moveResult.detailDisappearCounts:
        nums.add sum countsArray[ColorPuyo.low..ColorPuyo.high].mapIt it.len
    else:
      nums.add(
        moveResult.detailDisappearCounts.mapIt it[
          RequirementColorToCell[node.nazo.requirement.color.get]].len)
    result.numbers = some nums
  of DisappearConnect, DisappearConnectMore:
    var nums = newSeq[int](0)
    case node.nazo.requirement.color.get
    of RequirementColor.All, RequirementColor.Color:
      for countsArray in moveResult.detailDisappearCounts:
        for numsAtColor in countsArray[ColorPuyo.low..ColorPuyo.high]:
          nums &= numsAtColor.mapIt it.int
    else:
      for countsArray in moveResult.detailDisappearCounts:
        nums &= countsArray[
          RequirementColorToCell[node.nazo.requirement.color.get]].mapIt it.int
    result.numbers = some nums

  # set the number of puyoes in the field 
  if node.fieldCount.isSome:
    var
      addNum = 0
      disappearNum = 0
    case node.nazo.requirement.color.get
    of RequirementColor.All:
      addNum = 2
      disappearNum = moveResult.puyoCount
    of RequirementColor.Color:
      addNum = 2
      disappearNum = moveResult.colorCount
    of RequirementColor.Garbage:
      disappearNum = moveResult.totalDisappearCounts[Cell.Garbage]
    else:
      let color = RequirementColorToCell[node.nazo.requirement.color.get]
      addNum = pair.count color
      disappearNum = moveResult.totalDisappearCounts[color]
    result.fieldCount = some node.fieldCount.get.succ(addNum).pred disappearNum

  # set the maximum number of puyoes that can disappear
  if node.puyoCount.isSome:
    result.puyoCount =
      some node.puyoCount.get.pred(
        moveResult.totalDisappearCounts[
          RequirementColorToCell[node.nazo.requirement.color.get]])
  else:
    var puyoCounts: array[Puyo, Natural]
    for puyo in Puyo:
      puyoCounts[puyo] =
        node.puyoCounts.get[puyo].pred moveResult.totalDisappearCounts[puyo]
    result.puyoCounts = some puyoCounts

func children(node: Node): seq[Node] {.inline.} =
  ## Returns the children of the `node`.
  collect:
    for pos in (
        if node.nazo.environment.pairs.peekFirst.isDouble:
          node.nazo.environment.field.validDoublePositions
        else: node.nazo.environment.field.validPositions):
      node.child pos

# ------------------------------------------------
# Solve
# ------------------------------------------------

const
  SuruBarUpdateMs = 100
  ParallelSolvingWaitIntervalMs = 100

func isAccepted(node: Node): bool {.inline.} =
  ## Returns `true` if the node is in the accepted state.
  if node.numbers.isSome:
    let nowNums = node.numbers.get

    if node.isExactKind:
      if nowNums.allIt it != node.nazo.requirement.number.get:
        return false
    else:
      if nowNums.allIt it < node.nazo.requirement.number.get:
        return false
  else:
    if node.number.isSome or node.disappearColors.isSome:
      let nowNum =
        if node.number.isSome: node.number.get
        else: node.disappearColors.get.card

      if node.isExactKind:
        if nowNum != node.nazo.requirement.number.get:
          return false
      else:
        if nowNum < node.nazo.requirement.number.get:
          return false

  if node.fieldCount.isSome and node.fieldCount.get > 0:
    return false

  return true

func isNotSupported(nazo: NazoPuyo): bool {.inline.} =
  ## Returns `true` if the nazo puyo is not supported, *i.e.*, unsolvable.
  nazo.requirement.kind in {
    DisappearPlace, DisappearPlaceMore, DisappearConnect,
    DisappearConnectMore} and nazo.requirement.color.get ==
    RequirementColor.Garbage

func solveRec(node: Node): seq[Positions] {.inline.} =
  ## Solves the nazo puyo at the `node`.
  if node.isAccepted:
    result.add node.positions
    return

  if node.isLeaf or node.canPrune:
    return

  for child in node.children:
    result &= child.solveRec

proc solve*(
    nazo: NazoPuyo,
    parallelCount = (when defined(js): 1 else: max(countProcessors(), 1)),
    showProgress = false): seq[Positions] {.inline.} =
  ## Solves the nazo puyo.
  ## `parallelCount` and `showProgress` will be ignored on JS backend.
  if nazo.isNotSupported or nazo.moveCount == 0:
    return

  let node = nazo.initNode
  if node.canPrune:
    return

  let childNodes = node.children

  when defined(js):
    for node in childNodes:
      result &= node.solveRec
  else:
    # set up progress bar
    var bar: SuruBar
    if showProgress:
      bar = initSuruBar()
      bar[0].total = childNodes.len
      bar.setup

    # prepare solving
    let cpuCount = min(countProcessors(), childNodes.len)
    var
      futureAnswers = newSeqOfCap[FlowVar[seq[Positions]]] childNodes.len
      nextNodeIdx = Natural 0
      runningNodeIdxes = newSeq[Natural] cpuCount
      completeNodeCount = 0

    # run "first wave" node solving
    for cpuIdx in 0 ..< cpuCount:
      futureAnswers.add spawn childNodes[nextNodeIdx].solveRec
      runningNodeIdxes[cpuIdx] = nextNodeIdx
      nextNodeIdx.inc

    # solve
    while true:
      for cpuIdx in 0 ..< cpuCount:
        if not futureAnswers[runningNodeIdxes[cpuIdx]].isReady:
          continue

        # assign the next node to the processor
        if nextNodeIdx < childNodes.len:
          futureAnswers.add spawn childNodes[nextNodeIdx].solveRec
          runningNodeIdxes[cpuIdx] = nextNodeIdx
          nextNodeIdx.inc

        bar.inc
        bar.update SuruBarUpdateMs * 1000 * 1000

        # finish solving
        completeNodeCount.inc
        if completeNodeCount == childNodes.len:
          for future in futureAnswers:
            result &= ^future

          # `bar.finish` affects stdout, so we need to branch here
          if showProgress:
            bar.finish
          return

      sleep ParallelSolvingWaitIntervalMs

# ------------------------------------------------
# Inspect Solve
# ------------------------------------------------

func `&=`(sol1: var InspectAnswers, sol2: InspectAnswers) {.inline.} =
  sol1.answers &= sol2.answers
  sol1.visitNodeCount.inc sol2.visitNodeCount

func inspectSolveRec(node: Node, earlyStopping: bool): InspectAnswers
                    {.inline.} =
  ## Solves the nazo puyo at the node while keeping the number of visited nodes.
  result.visitNodeCount.inc

  if node.isAccepted:
    result.answers.add node.positions
    return

  if node.isLeaf or node.canPrune:
    return

  for child in node.children:
    result &= child.inspectSolveRec earlyStopping
    if earlyStopping and result.answers.len > 1:
      return

proc inspectSolve*(
    nazo: NazoPuyo,
    parallelCount = (when defined(js): 1 else: max(countProcessors(), 1)),
    showProgress = false,
    earlyStopping = false): InspectAnswers {.inline.} =
  ## Solves the nazo puyo while keeping the number of visited nodes.
  ## If `earlyStopping` is `true`, searching is interrupted if any solution is
  ## found.
  ## `parallelCount` and `showProgress` will be ignored on JS backend.
  if nazo.isNotSupported or nazo.moveCount == 0:
    return

  let node = nazo.initNode
  if node.canPrune:
    return

  let childNodes = node.children

  when defined(js):
    for node in childNodes:
      result &= node.inspectSolveRec earlyStopping
  else:
    # set up progress bar
    var bar: SuruBar
    if showProgress:
      bar = initSuruBar()
      bar[0].total = childNodes.len
      bar.setup

    # prepare solving
    let cpuCount = min(countProcessors(), childNodes.len)
    var
      futureAnswers = newSeqOfCap[FlowVar[InspectAnswers]] childNodes.len
      nextNodeIdx = Natural 0
      runningNodeIdxes = newSeq[Natural] cpuCount
      completeNodeCount = 0

    # run "first wave" node solving
    for cpuIdx in 0 ..< cpuCount:
      futureAnswers.add spawn(
        childNodes[nextNodeIdx].inspectSolveRec earlyStopping)
      runningNodeIdxes[cpuIdx] = nextNodeIdx
      nextNodeIdx.inc

    # solve
    while true:
      for cpuIdx in 0 ..< cpuCount:
        if not futureAnswers[runningNodeIdxes[cpuIdx]].isReady:
          continue

        # assign the next node to the processor
        if nextNodeIdx < childNodes.len:
          futureAnswers.add spawn(
            childNodes[nextNodeIdx].inspectSolveRec earlyStopping)
          runningNodeIdxes[cpuIdx] = nextNodeIdx
          nextNodeIdx.inc

        bar.inc
        bar.update SuruBarUpdateMs * 1000 * 1000

        # finish solving
        completeNodeCount.inc
        if completeNodeCount == childNodes.len:
          for future in futureAnswers:
            result &= ^future

          # `bar.finish` affects stdout, so we need to branch here
          if showProgress:
            bar.finish
          return

      sleep ParallelSolvingWaitIntervalMs
