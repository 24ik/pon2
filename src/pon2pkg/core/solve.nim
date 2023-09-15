## This module implements the solver.
##

const
  singleThread {.booldefine.} = false
  SingleThread = singleThread or defined(js)

import deques
import math
import options
import sequtils
import std/setutils
import sugar
import suru
import tables

import nazopuyo_core
import puyo_core
import puyo_core/environment

when not SingleThread:
  import threadpool

type
  Node = tuple
    ## Node of solution search tree.
    nazo: NazoPuyo
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
    ## Sequence of Nazo Puyo answers with the number of search tree nodes visited.
    answers: seq[Positions]
    visitNodeCount: Positive

# ------------------------------------------------
# NazoPuyo -> Node
# ------------------------------------------------

const RequirementColorToCell = {
  RequirementColor.GARBAGE: Cell.GARBAGE,
  RequirementColor.RED: Cell.RED,
  RequirementColor.GREEN: Cell.GREEN,
  RequirementColor.BLUE: Cell.BLUE,
  RequirementColor.YELLOW: Cell.YELLOW,
  RequirementColor.PURPLE: Cell.PURPLE,
}.toTable

func toNode(nazo: NazoPuyo): Node {.inline.} =
  ## Converts the nazo puyo to the node.
  result.nazo = nazo
  result.positions = newSeqOfCap[Option[Position]] nazo.moveCount

  # kinds
  result.isChainKind = nazo.requirement.kind in {CHAIN, CHAIN_MORE, CHAIN_CLEAR, CHAIN_MORE_CLEAR}
  result.isExactKind = nazo.requirement.kind in {
    DISAPPEAR_COLOR,
    DISAPPEAR_COUNT,
    CHAIN,
    CHAIN_CLEAR,
    DISAPPEAR_COLOR_SAMETIME,
    DISAPPEAR_COUNT_SAMETIME,
    DISAPPEAR_PLACE,
    DISAPPEAR_CONNECT}

  # set property corresponding to 'n' in the kind
  case nazo.requirement.kind
  of CLEAR:
    discard
  of DISAPPEAR_COLOR, DISAPPEAR_COLOR_MORE:
    result.disappearColors = some set[ColorPuyo]({})
  of DISAPPEAR_COUNT, DISAPPEAR_COUNT_MORE, CHAIN, CHAIN_MORE, CHAIN_CLEAR, CHAIN_MORE_CLEAR:
    result.number = some 0.Natural
  else:
    result.numbers = some newSeq[int] 0

  # number of puyoes in the field
  if nazo.requirement.kind in {CLEAR, CHAIN_CLEAR, CHAIN_MORE_CLEAR}:
    case nazo.requirement.color.get
    of RequirementColor.ALL:
      result.fieldCount = some nazo.environment.field.countPuyo.Natural
    of RequirementColor.COLOR:
      result.fieldCount = some nazo.environment.field.countColor.Natural
    of RequirementColor.GARBAGE:
      result.fieldCount = some nazo.environment.field.countGarbage.Natural
    else:
      result.fieldCount = some Natural nazo.environment.field.count RequirementColorToCell[nazo.requirement.color.get]

  # number of puyoes that can disappear
  if (
    result.isChainKind or
    nazo.requirement.kind in NoColorKinds or
    nazo.requirement.color.get in {RequirementColor.ALL, RequirementColor.GARBAGE, RequirementColor.COLOR}
  ):
    var puyoCounts: array[Puyo, Natural]
    puyoCounts[Cell.GARBAGE] = nazo.environment.countGarbage
    for color in ColorPuyo:
      puyoCounts[color] = Natural nazo.environment.count color
    result.puyoCounts = some puyoCounts
  else:
    result.puyoCount = some Natural nazo.environment.count RequirementColorToCell[nazo.requirement.color.get]

# ------------------------------------------------
# Prune
# ------------------------------------------------

func filter4(num: int): int {.inline.} =
  ## If `num >= 4`, returns `num`.
  ## Otherwise, returns `0`.
  num * (num >= 4).int

func canPrune(node: Node): bool {.inline.} =
  ## Returns `true` if the `node` is in the unsolvable state.
  if node.nazo.environment.field.isDead:
    return true

  # check if it is impossible to clear the field
  if node.fieldCount.isSome:
    if node.puyoCount.isSome:
      if node.puyoCount.get in 1 .. 3:
        return true
    else:
      if node.puyoCounts.get[ColorPuyo.low .. ColorPuyo.high].anyIt it in 1 .. 3:
        return true

  # check the number corresponding to 'n' in the kind
  var
    nowNum = 0
    possibleNum = 0
    targetNum = if node.nazo.requirement.number.isSome: node.nazo.requirement.number.get.int else: -1
  case node.nazo.requirement.kind
  of CLEAR:
    discard
  of DISAPPEAR_COLOR, DISAPPEAR_COLOR_MORE, DISAPPEAR_COLOR_SAMETIME, DISAPPEAR_COLOR_MORE_SAMETIME:
    if node.nazo.requirement.kind in {DISAPPEAR_COLOR, DISAPPEAR_COLOR_MORE}:
      nowNum = node.disappearColors.get.card

    possibleNum = node.puyoCounts.get[ColorPuyo.low .. ColorPuyo.high].countIt it >= 4
  of DISAPPEAR_COUNT, DISAPPEAR_COUNT_MORE, DISAPPEAR_COUNT_SAMETIME, DISAPPEAR_COUNT_MORE_SAMETIME:
    if node.nazo.requirement.kind in {DISAPPEAR_COUNT, DISAPPEAR_COUNT_MORE}:
      nowNum = node.number.get

    if node.puyoCount.isSome:
      possibleNum = node.puyoCount.get.filter4
    else:
      let colorPossibleNum = sum node.puyoCounts.get[ColorPuyo.low .. ColorPuyo.high].mapIt it.filter4
      if node.nazo.requirement.color.get in {RequirementColor.ALL, RequirementColor.COLOR}:
        possibleNum = colorPossibleNum
      if node.nazo.requirement.color.get in {RequirementColor.ALL, RequirementColor.GARBAGE}:
        if colorPossibleNum > 0:
          possibleNum.inc node.puyoCounts.get[Cell.GARBAGE]
  of CHAIN, CHAIN_MORE, CHAIN_CLEAR, CHAIN_MORE_CLEAR:
    possibleNum = sum node.puyoCounts.get[ColorPuyo.low .. ColorPuyo.high].mapIt it div 4
  of DISAPPEAR_PLACE, DISAPPEAR_PLACE_MORE:
    if node.puyoCount.isSome:
      possibleNum = node.puyoCount.get div 4
    else:
      possibleNum = sum node.puyoCounts.get[ColorPuyo.low .. ColorPuyo.high].mapIt it div 4
  of DISAPPEAR_CONNECT, DISAPPEAR_CONNECT_MORE:
    if node.puyoCount.isSome:
      possibleNum = node.puyoCount.get.filter4
    else:
      possibleNum = max node.puyoCounts.get[ColorPuyo.low .. ColorPuyo.high].mapIt it.filter4

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
  let moveFn =
    if node.nazo.requirement.kind in {
      CLEAR,
      DISAPPEAR_COLOR,
      DISAPPEAR_COLOR_MORE,
      DISAPPEAR_COUNT,
      DISAPPEAR_COUNT_MORE,
      CHAIN,
      CHAIN_MORE,
      CHAIN_CLEAR,
      CHAIN_MORE_CLEAR,
    }:
      environment.moveWithRoughTracking
    elif node.nazo.requirement.kind in {
      DISAPPEAR_COLOR_SAMETIME, DISAPPEAR_COLOR_MORE_SAMETIME, DISAPPEAR_COUNT_SAMETIME, DISAPPEAR_COUNT_MORE_SAMETIME
    }:
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
  of CLEAR:
    discard
  of DISAPPEAR_COLOR, DISAPPEAR_COLOR_MORE:
    result.disappearColors =
      some node.disappearColors.get + (ColorPuyo.toSeq.filterIt moveResult.totalDisappearCounts.get[it] > 0).toSet
  of DISAPPEAR_COUNT, DISAPPEAR_COUNT_MORE:
    result.number = some node.number.get.succ(
      case node.nazo.requirement.color.get
      of RequirementColor.AlL:
        moveResult.puyoCount
      of RequirementColor.COLOR:
        moveResult.colorCount
      else:
        moveResult.totalDisappearCounts.get[RequirementColorToCell[node.nazo.requirement.color.get]]
    )
  of CHAIN, CHAIN_MORE, CHAIN_CLEAR, CHAIN_MORE_CLEAR:
    result.number = some moveResult.chainCount
  of DISAPPEAR_COLOR_SAMETIME, DISAPPEAR_COLOR_MORE_SAMETIME:
    let numbers = collect:
      for countsArray in moveResult.disappearCounts.get:
        countsArray[ColorPuyo.low .. ColorPuyo.high].countIt it > 0
    result.numbers = some numbers
  of DISAPPEAR_COUNT_SAMETIME, DISAPPEAR_COUNT_MORE_SAMETIME:
    let nums = case node.nazo.requirement.color.get
    of RequirementColor.ALL:
      moveResult.puyoCounts
    of RequirementColor.COLOR:
      moveResult.colorCounts
    else:
      moveResult.disappearCounts.get.mapIt it[RequirementColorToCell[node.nazo.requirement.color.get]].int
    result.numbers = some nums
  of DISAPPEAR_PLACE, DISAPPEAR_PLACE_MORE:
    var nums: seq[int]
    case node.nazo.requirement.color.get
    of RequirementColor.ALL, RequirementColor.COLOR:
      for countsArray in moveResult.detailDisappearCounts.get:
        nums.add sum countsArray[ColorPuyo.low .. ColorPuyo.high].mapIt it.len
    else:
      nums.add(
        moveResult.detailDisappearCounts.get.mapIt it[RequirementColorToCell[node.nazo.requirement.color.get]].len)
    result.numbers = some nums
  of DISAPPEAR_CONNECT, DISAPPEAR_CONNECT_MORE:
    var nums: seq[int]
    case node.nazo.requirement.color.get
    of RequirementColor.ALL, RequirementColor.COLOR:
      for countsArray in moveResult.detailDisappearCounts.get:
        for numsAtColor in countsArray[ColorPuyo.low .. ColorPuyo.high]:
          nums &= numsAtColor.mapIt it.int
    else:
      for countsArray in moveResult.detailDisappearCounts.get:
        nums &= countsArray[RequirementColorToCell[node.nazo.requirement.color.get]].mapIt it.int
    result.numbers = some nums

  # set the number of puyoes in the field 
  if node.fieldCount.isSome:
    var
      addNum = 0
      disappearNum = 0
    case node.nazo.requirement.color.get
    of RequirementColor.ALL:
      addNum = 2
      disappearNum = moveResult.puyoCount
    of RequirementColor.COLOR:
      addNum = 2
      disappearNum = moveResult.colorCount
    of RequirementColor.GARBAGE:
      disappearNum = moveResult.totalDisappearCounts.get[Cell.GARBAGE]
    else:
      let color = RequirementColorToCell[node.nazo.requirement.color.get]
      addNum = pair.count color
      disappearNum = moveResult.totalDisappearCounts.get[color]
    result.fieldCount = some node.fieldCount.get.succ(addNum).pred disappearNum

  # set the maximum number of puyoes that can disappear
  if node.puyoCount.isSome:
    result.puyoCount =
      some node.puyoCount.get.pred(
        moveResult.totalDisappearCounts.get[RequirementColorToCell[node.nazo.requirement.color.get]])
  else:
    var puyoCounts: array[Puyo, Natural]
    for puyo in Puyo:
      puyoCounts[puyo] = node.puyoCounts.get[puyo].pred moveResult.totalDisappearCounts.get[puyo]
    result.puyoCounts = some puyoCounts

func children(node: Node): seq[Node] {.inline.} =
  ## Returns the children of the `node`.
  collect:
    for pos in (
      if node.nazo.environment.pairs.peekFirst.isDouble: node.nazo.environment.field.validDoublePositions
      else: node.nazo.environment.field.validPositions
    ):
      node.child pos

# ------------------------------------------------
# Solve
# ------------------------------------------------

const SuruBarUpdateMs = 100

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
      let nowNum = if node.number.isSome: node.number.get else: node.disappearColors.get.card

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
  ## Returns `true` if the nazo puyo is not supported, i.e., unsolvable.
  nazo.requirement.kind in {DISAPPEAR_PLACE, DISAPPEAR_PLACE_MORE, DISAPPEAR_CONNECT, DISAPPEAR_CONNECT_MORE} and
  nazo.requirement.color.get == RequirementColor.GARBAGE

func solveRec(node: Node): seq[Positions] {.inline.} =
  ## Solves the nazo puyo at the `node`.
  if node.isAccepted:
    result.add node.positions
    return

  if node.isLeaf or node.canPrune:
    return

  for child in node.children:
    result &= child.solveRec

proc solve*(nazo: NazoPuyo, showProgress = false): seq[Positions] {.inline.} =
  ## Solves the nazo puyo.
  if nazo.isNotSupported or nazo.moveCount == 0:
    return

  let node = nazo.toNode
  if node.canPrune:
    return

  let childNodes = node.children

  var bar: SuruBar
  if showProgress:
    bar = initSuruBar()
    bar[0].total = childNodes.len
    bar.setup

  when SingleThread:
    for child in childNodes:
      result &= child.solveRec

      if showProgress:
        bar.inc
        bar.update SuruBarUpdateMs * 1000 * 1000
  else:
    let futureAnswers = collect:
      for child in childNodes:
        spawn child.solveRec

    for answer in futureAnswers:
      result &= ^answer

      if showProgress:
        bar.inc
        bar.update SuruBarUpdateMs * 1000 * 1000

  if showProgress:
    bar.finish

# ------------------------------------------------
# Inspect Solve
# ------------------------------------------------

func `&=`(sol1: var InspectAnswers, sol2: InspectAnswers) {.inline.} =
  sol1.answers &= sol2.answers
  sol1.visitNodeCount.inc sol2.visitNodeCount

func inspectSolveRec(node: Node, earlyStopping: bool): InspectAnswers {.inline.} =
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

proc inspectSolve*(nazo: NazoPuyo, earlyStopping = false, showProgress = false): InspectAnswers {.inline.} =
  ## Solves the nazo puyo while keeping the number of visited nodes.
  ## If `earlyStopping` is `true`, searching is interrupted if any solution is found.
  if nazo.isNotSupported or nazo.moveCount == 0:
    return

  let node = nazo.toNode
  if node.canPrune:
    return

  let childNodes = node.children

  var bar: SuruBar
  if showProgress:
    bar = initSuruBar()
    bar[0].total = childNodes.len
    bar.setup

  when SingleThread:
    for child in node.children:
      result &= child.inspectSolveRec earlyStopping

      if showProgress:
        bar.inc
        bar.update SuruBarUpdateMs * 1000 * 1000
  else:
    let futureAnswers = collect:
      for child in childNodes:
        spawn child.inspectSolveRec earlyStopping

    for answer in futureAnswers:
      result &= ^answer

      if showProgress:
        bar.inc
        bar.update SuruBarUpdateMs * 1000 * 1000

  if showProgress:
    bar.finish
