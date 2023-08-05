## This module implements the solver.
##

const
  singleThread {.booldefine.} = false
  SingleThread = singleThread or defined js

import deques
import math
import options
import sequtils
import std/setutils
import strutils
import strformat
import sugar
import tables

import nazopuyo_core
import puyo_core
import puyo_core/env as envLib

when not SingleThread:
  import threadpool

type
  Node = tuple
    ## Node of solution search tree.
    nazo: Nazo
    positions: Positions

    isChainKind: bool
    isExactKind: bool

    # used to check if the requirement are satisfied
    disappearColors: Option[set[ColorPuyo]]
    num: Option[Natural]
    nums: Option[seq[int]]

    # used to check if the field is cleared
    fieldNum: Option[Natural]

    # used to calculate the maximum number of puyoes that can disappear
    puyoNum: Option[Natural]
    puyoNums: Option[array[Puyo, Natural]]

  Solution* = Positions ## Nazo Puyo solution.
  Solutions* = seq[Solution] ## Sequence of Nazo Puyo solutions.
  InspectSolutions* = tuple
    ## Sequence of Nazo Puyo solutions with the number of search tree nodes visited.
    solutions: Solutions
    visitNodeNum: Positive

const RequirementColorToCell = {
  RequirementColor.GARBAGE: Cell.GARBAGE,
  RequirementColor.RED: Cell.RED,
  RequirementColor.GREEN: Cell.GREEN,
  RequirementColor.BLUE: Cell.BLUE,
  RequirementColor.YELLOW: Cell.YELLOW,
  RequirementColor.PURPLE: Cell.PURPLE,
}.toTable

# ------------------------------------------------
# Nazo -> Node
# ------------------------------------------------

func toNode(nazo: Nazo): Node {.inline.} =
  ## Converts the `nazo` to the node.
  result.nazo = nazo
  result.positions = newSeqOfCap[Option[Position]] nazo.moveNum

  # kinds
  result.isChainKind = nazo.req.kind in {CHAIN, CHAIN_MORE, CHAIN_CLEAR, CHAIN_MORE_CLEAR}
  result.isExactKind = nazo.req.kind in {
    DISAPPEAR_COLOR,
    DISAPPEAR_NUM,
    CHAIN,
    CHAIN_CLEAR,
    DISAPPEAR_COLOR_SAMETIME,
    DISAPPEAR_NUM_SAMETIME,
    DISAPPEAR_PLACE,
    DISAPPEAR_CONNECT}

  # numbers corresponding to 'n' in the kind
  case nazo.req.kind
  of CLEAR:
    discard
  of DISAPPEAR_COLOR, DISAPPEAR_COLOR_MORE:
    result.disappearColors = some set[ColorPuyo]({})
  of DISAPPEAR_NUM, DISAPPEAR_NUM_MORE, CHAIN, CHAIN_MORE, CHAIN_CLEAR, CHAIN_MORE_CLEAR:
    result.num = some 0.Natural
  else:
    result.nums = some newSeq[int] 0

  # number of puyoes in the field
  if nazo.req.kind in {CLEAR, CHAIN_CLEAR, CHAIN_MORE_CLEAR}:
    case nazo.req.color.get
    of RequirementColor.ALL:
      result.fieldNum = some nazo.env.field.puyoNum.Natural
    of RequirementColor.COLOR:
      result.fieldNum = some nazo.env.field.colorNum.Natural
    of RequirementColor.GARBAGE:
      result.fieldNum = some nazo.env.field.garbageNum.Natural
    else:
      result.fieldNum = some Natural nazo.env.field.colorNum RequirementColorToCell[nazo.req.color.get]

  # number of puyoes that can disappear
  if (
    result.isChainKind or
    nazo.req.kind in RequirementKindsWithoutColor or
    nazo.req.color.get in {RequirementColor.ALL, RequirementColor.GARBAGE, RequirementColor.COLOR}
  ):
    var puyoNums: array[Puyo, Natural]
    puyoNums[Cell.GARBAGE] = nazo.env.garbageNum
    for color in ColorPuyo:
      puyoNums[color] = Natural nazo.env.colorNum color
    result.puyoNums = some puyoNums
  else:
    result.puyoNum = some Natural nazo.env.colorNum RequirementColorToCell[nazo.req.color.get]

# ------------------------------------------------
# Check
# ------------------------------------------------

func isAccepted(node: Node): bool {.inline.} =
  ## Returns `true` if the `node` is in the accepted state.
  if node.nums.isSome:
    let nowNums = node.nums.get

    if node.isExactKind:
      if nowNums.allIt it != node.nazo.req.num.get:
        return false
    else:
      if nowNums.allIt it < node.nazo.req.num.get:
        return false
  else:
    if node.num.isSome or node.disappearColors.isSome:
      let nowNum = if node.num.isSome: node.num.get else: node.disappearColors.get.card

      if node.isExactKind:
        if nowNum != node.nazo.req.num.get:
          return false
      else:
        if nowNum < node.nazo.req.num.get:
          return false

  if node.fieldNum.isSome and node.fieldNum.get > 0:
    return false

  return true

# ------------------------------------------------
# Prune
# ------------------------------------------------

func filter4(num: int): int {.inline.} =
  ## If `num >= 4`, returns `num`.
  ## Otherwise, returns `0`.
  num * (num >= 4).int

func canPrune(node: Node): bool {.inline.} =
  ## Returns `true` if the `node` is in the unsolvable state.
  if node.nazo.env.field.isDead:
    return true

  # check if it is impossible to clear the field
  if node.fieldNum.isSome:
    if node.puyoNum.isSome:
      if node.puyoNum.get in 1 .. 3:
        return true
    else:
      if node.puyoNums.get[ColorPuyo.low .. ColorPuyo.high].anyIt it in 1 .. 3:
        return true

  # check the number corresponding to 'n' in the kind
  var
    nowNum = 0
    possibleNum = 0
    targetNum = if node.nazo.req.num.isSome: node.nazo.req.num.get.int else: -1
  case node.nazo.req.kind
  of CLEAR:
    discard
  of DISAPPEAR_COLOR, DISAPPEAR_COLOR_MORE, DISAPPEAR_COLOR_SAMETIME, DISAPPEAR_COLOR_MORE_SAMETIME:
    if node.nazo.req.kind in {DISAPPEAR_COLOR, DISAPPEAR_COLOR_MORE}:
      nowNum = node.disappearColors.get.card

    possibleNum = node.puyoNums.get[ColorPuyo.low .. ColorPuyo.high].countIt it >= 4
  of DISAPPEAR_NUM, DISAPPEAR_NUM_MORE, DISAPPEAR_NUM_SAMETIME, DISAPPEAR_NUM_MORE_SAMETIME:
    if node.nazo.req.kind in {DISAPPEAR_NUM, DISAPPEAR_NUM_MORE}:
      nowNum = node.num.get

    if node.puyoNum.isSome:
      possibleNum = node.puyoNum.get.filter4
    else:
      let colorPossibleNum = sum node.puyoNums.get[ColorPuyo.low .. ColorPuyo.high].mapIt it.filter4
      if node.nazo.req.color.get in {RequirementColor.ALL, RequirementColor.COLOR}:
        possibleNum = colorPossibleNum
      if node.nazo.req.color.get in {RequirementColor.ALL, RequirementColor.GARBAGE}:
        if colorPossibleNum > 0:
          possibleNum.inc node.puyoNums.get[Cell.GARBAGE]
  of CHAIN, CHAIN_MORE, CHAIN_CLEAR, CHAIN_MORE_CLEAR:
    possibleNum = sum node.puyoNums.get[ColorPuyo.low .. ColorPuyo.high].mapIt it div 4
  of DISAPPEAR_PLACE, DISAPPEAR_PLACE_MORE:
    if node.puyoNum.isSome:
      possibleNum = node.puyoNum.get div 4
    else:
      possibleNum = sum node.puyoNums.get[ColorPuyo.low .. ColorPuyo.high].mapIt it div 4
  of DISAPPEAR_CONNECT, DISAPPEAR_CONNECT_MORE:
    if node.puyoNum.isSome:
      possibleNum = node.puyoNum.get.filter4
    else:
      possibleNum = max node.puyoNums.get[ColorPuyo.low .. ColorPuyo.high].mapIt it.filter4

  if nowNum + possibleNum < targetNum:
    return true

# ------------------------------------------------
# Search Tree Operation
# ------------------------------------------------

func isLeaf(node: Node): bool {.inline.} =
  ## Returns `true` if the `node` is the leaf (i.e., all moves are completed).
  node.positions.len == node.nazo.moveNum

func child(node: Node, pos: Position): Node {.inline.} =
  ## Returns the child of the `node` with the `pos` edge.
  let moveFn =
    if node.nazo.req.kind in {
      CLEAR,
      DISAPPEAR_COLOR,
      DISAPPEAR_COLOR_MORE,
      DISAPPEAR_NUM,
      DISAPPEAR_NUM_MORE,
      CHAIN,
      CHAIN_MORE,
      CHAIN_CLEAR,
      CHAIN_MORE_CLEAR,
    }:
      envLib.moveWithRoughTracking
    elif node.nazo.req.kind in {
      DISAPPEAR_COLOR_SAMETIME, DISAPPEAR_COLOR_MORE_SAMETIME, DISAPPEAR_NUM_SAMETIME, DISAPPEAR_NUM_MORE_SAMETIME
    }:
      envLib.moveWithDetailTracking
    else:
      envLib.moveWithFullTracking
  
  result = node
  result.positions.add pos.some

  let
    pair = result.nazo.env.pairs.peekFirst
    moveResult = result.nazo.env.moveFn pos

  # set the number corresponding to 'n' in the kind
  case node.nazo.req.kind
  of CLEAR:
    discard
  of DISAPPEAR_COLOR, DISAPPEAR_COLOR_MORE:
    result.disappearColors =
      some node.disappearColors.get + (ColorPuyo.toSeq.filterIt moveResult.totalDisappearNums.get[it] > 0).toSet
  of DISAPPEAR_NUM, DISAPPEAR_NUM_MORE:
    result.num = some node.num.get.succ(
      case node.nazo.req.color.get
      of RequirementColor.AlL:
        moveResult.puyoNum
      of RequirementColor.COLOR:
        moveResult.colorNum
      else:
        moveResult.totalDisappearNums.get[RequirementColorToCell[node.nazo.req.color.get]]
    )
  of CHAIN, CHAIN_MORE, CHAIN_CLEAR, CHAIN_MORE_CLEAR:
    result.num = some moveResult.chainNum
  of DISAPPEAR_COLOR_SAMETIME, DISAPPEAR_COLOR_MORE_SAMETIME:
    let nums = collect:
      for numsArray in moveResult.disappearNums.get:
        numsArray[ColorPuyo.low .. ColorPuyo.high].countIt it > 0
    result.nums = some nums
  of DISAPPEAR_NUM_SAMETIME, DISAPPEAR_NUM_MORE_SAMETIME:
    let nums = case node.nazo.req.color.get
    of RequirementColor.ALL:
      moveResult.puyoNums
    of RequirementColor.COLOR:
      moveResult.colorNums
    else:
      moveResult.disappearNums.get.mapIt it[RequirementColorToCell[node.nazo.req.color.get]].int
    result.nums = some nums
  of DISAPPEAR_PLACE, DISAPPEAR_PLACE_MORE:
    var nums: seq[int]
    case node.nazo.req.color.get
    of RequirementColor.ALL, RequirementColor.COLOR:
      for numsArray in moveResult.detailDisappearNums.get:
        nums.add sum numsArray[ColorPuyo.low .. ColorPuyo.high].mapIt it.len
    else:
      nums.add moveResult.detailDisappearNums.get.mapIt it[RequirementColorToCell[node.nazo.req.color.get]].len
    result.nums = some nums
  of DISAPPEAR_CONNECT, DISAPPEAR_CONNECT_MORE:
    var nums: seq[int]
    case node.nazo.req.color.get
    of RequirementColor.ALL, RequirementColor.COLOR:
      for numsArray in moveResult.detailDisappearNums.get:
        for numsAtColor in numsArray[ColorPuyo.low .. ColorPuyo.high]:
          nums &= numsAtColor.mapIt it.int
    else:
      for numsArray in moveResult.detailDisappearNums.get:
        nums &= numsArray[RequirementColorToCell[node.nazo.req.color.get]].mapIt it.int
    result.nums = some nums

  # set the number of puyoes in the field 
  if node.fieldNum.isSome:
    var
      addNum = 0
      disappearNum = 0
    case node.nazo.req.color.get
    of RequirementColor.ALL:
      addNum = 2
      disappearNum = moveResult.puyoNum
    of RequirementColor.COLOR:
      addNum = 2
      disappearNum = moveResult.colorNum
    of RequirementColor.GARBAGE:
      disappearNum = moveResult.totalDisappearNums.get[Cell.GARBAGE]
    else:
      let color = RequirementColorToCell[node.nazo.req.color.get]
      addNum = pair.colorNum color
      disappearNum = moveResult.totalDisappearNums.get[color]
    result.fieldNum = some node.fieldNum.get.succ(addNum).pred disappearNum

  # set the maximum number of puyoes that can disappear
  if node.puyoNum.isSome:
    result.puyoNum =
      some node.puyoNum.get.pred moveResult.totalDisappearNums.get[RequirementColorToCell[node.nazo.req.color.get]]
  else:
    var puyoNums: array[Puyo, Natural]
    for puyo in Puyo:
      puyoNums[puyo] = node.puyoNums.get[puyo].pred moveResult.totalDisappearNums.get[puyo]
    result.puyoNums = some puyoNums

func children(node: Node): seq[Node] {.inline.} =
  ## Returns the children of the `node`.
  collect:
    for pos in (
      if node.nazo.env.pairs.peekFirst.isDouble: node.nazo.env.field.validDoublePositions
      else: node.nazo.env.field.validPositions
    ):
      node.child pos

# ------------------------------------------------
# Solve
# ------------------------------------------------

func solveRec(node: Node): Solutions {.inline.} =
  ## Solves the nazo puyo at the `node`.
  if node.isAccepted:
    result.add node.positions
    return

  if node.isLeaf or node.canPrune:
    return

  for child in node.children:
    result &= child.solveRec

proc solve*(nazo: Nazo): Solutions {.inline.} =
  ## Solves the nazo puyo at the `node`.
  if (
    nazo.req.kind in {DISAPPEAR_PLACE, DISAPPEAR_PLACE_MORE, DISAPPEAR_CONNECT, DISAPPEAR_CONNECT_MORE} and
    nazo.req.color.get == RequirementColor.GARBAGE
  ):
    return
  if nazo.env.pairs.len == 0:
    return

  let node = nazo.toNode
  if node.canPrune:
    return

  when SingleThread:
    for child in node.children:
      result &= child.solveRec
  else:
    let children = node.children

    var futureSolutions = newSeqOfCap[FlowVar[Solutions]] children.len
    for child in children:
      futureSolutions.add child.solveRec.spawn
    for sol in futureSolutions:
      result &= ^sol

proc solve*(url: string, domain = ISHIKAWAPUYO): Option[seq[string]] {.inline.} =
  ## Solves the nazo puyo represented by the `url`.
  ## If the `url` is invalid, returns `none`.
  let nazo = url.toNazo true
  if nazo.isNone:
    return

  let urls = collect:
    for sol in nazo.get.solve:
      nazo.get.toUrl sol.some, domain
  return some urls

# ------------------------------------------------
# Inspect Solve
# ------------------------------------------------

func `&=`(sol1: var InspectSolutions, sol2: InspectSolutions) {.inline.} =
  sol1.solutions &= sol2.solutions
  sol1.visitNodeNum.inc sol2.visitNodeNum

func inspectSolveRec(node: Node, earlyStopping: bool): InspectSolutions {.inline.} =
  ## Solves the nazo puyo at the `node` while keeping the number of visited nodes.
  result.visitNodeNum.inc

  if node.isAccepted:
    result.solutions.add node.positions
    return

  if node.isLeaf or node.canPrune:
    return

  for child in node.children:
    result &= child.inspectSolveRec earlyStopping
    if earlyStopping and result.solutions.len > 1:
      return

proc inspectSolve*(nazo: Nazo, earlyStopping = false): InspectSolutions {.inline.} =
  ## Solves the nazo puyo at the `node` while keeping the number of visited nodes.
  ## If `earlyStopping` is specified, searching is interrupted if any solution is found.
  if (
    nazo.req.kind in {DISAPPEAR_PLACE, DISAPPEAR_PLACE_MORE, DISAPPEAR_CONNECT, DISAPPEAR_CONNECT_MORE} and
    nazo.req.color.get == RequirementColor.GARBAGE
  ):
    return
  if nazo.env.pairs.len == 0:
    return

  let node = nazo.toNode
  if node.canPrune:
    return

  when SingleThread:
    for child in node.children:
      result &= child.inspectSolveRec earlyStopping
  else:
    let children = node.children

    var futureSolutions = newSeqOfCap[FlowVar[InspectSolutions]] children.len
    for child in children:
      futureSolutions.add spawn child.inspectSolveRec earlyStopping
    for sol in futureSolutions:
      result &= ^sol

proc inspectSolve*(url: string, earlyStopping = false, domain = ISHIKAWAPUYO): Option[
  tuple[urls: seq[string], visitNodeNum: int]
] {.inline.} =
  ## Solves the nazo puyo represented by the `url` while keeping the number of visited nodes.
  ## If `earlyStopping` is specified, searching is interrupted if any solution is found.
  ## If the `url` is invalid, returns `none`.
  let nazo = url.toNazo true
  if nazo.isNone:
    return

  let (solutions, visitNodeNum) = nazo.get.inspectSolve earlyStopping
  return some (urls: solutions.mapIt nazo.get.toUrl(it.some, domain), visitNodeNum: visitNodeNum.int)

# ------------------------------------------------
# Solution -> string
# ------------------------------------------------

func `$`*(sol: Solution): string {.inline.} =
  let
    posStrs = collect:
      for pos in sol:
        $pos
    solStr = posStrs.join ", "

  return &"@[{solStr}]"
