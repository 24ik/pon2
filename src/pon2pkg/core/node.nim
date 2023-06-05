## This module implements a node of a search tree for solving.
##

import deques
import math
import options
import sequtils
import std/setutils
import sugar
import tables

import nazopuyo_core
import puyo_core
import puyo_core/env

type
  Node* = tuple
    nazo: Nazo
    positions: Positions

    isChainKind: bool
    isExactKind: bool

    # used for checking whether the requirement is satisfied or not
    disappearColors: Option[set[ColorPuyo]]
    num: Option[Natural]
    nums: Option[seq[int]]

    # used for checking whether the field is clear or not
    fieldNum: Option[Natural]

    # used for calculating the maximum number of disappearing
    puyoNum: Option[Natural]
    puyoNums: Option[array[Puyo, Natural]]

const RequirementColorToCell = {
  RequirementColor.GARBAGE: Cell.GARBAGE,
  RequirementColor.RED: Cell.RED,
  RequirementColor.GREEN: Cell.GREEN,
  RequirementColor.BLUE: Cell.BLUE,
  RequirementColor.YELLOW: Cell.YELLOW,
  RequirementColor.PURPLE: Cell.PURPLE,
}.toTable

func toNode*(nazo: Nazo): Node {.inline.} =
  ## Converts the nazo to a node.
  result.nazo = nazo
  result.positions = newSeqOfCap[Option[Position]] nazo.moveNum

  result.isChainKind = nazo.req.kind in {CHAIN, CHAIN_MORE, CHAIN_CLEAR, CHAIN_MORE_CLEAR}
  result.isExactKind = nazo.req.kind in {
    DISAPPEAR_COLOR,
    DISAPPEAR_NUM,
    CHAIN,
    CHAIN_CLEAR,
    DISAPPEAR_COLOR_SAMETIME,
    DISAPPEAR_NUM_SAMETIME,
    DISAPPEAR_PLACE,
    DISAPPEAR_CONNECT,
  }

  case nazo.req.kind
  of CLEAR:
    discard
  of DISAPPEAR_COLOR, DISAPPEAR_COLOR_MORE:
    result.disappearColors = some set[ColorPuyo]({})
  of DISAPPEAR_NUM, DISAPPEAR_NUM_MORE, CHAIN, CHAIN_MORE, CHAIN_CLEAR, CHAIN_MORE_CLEAR:
    result.num = some 0.Natural
  else:
    result.nums = some newSeq[int] 0

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

  if result.isChainKind or nazo.req.kind in RequirementKindsWithoutColor or nazo.req.color.get in {
    RequirementColor.ALL, RequirementColor.GARBAGE, RequirementColor.COLOR
  }:
    var puyoNums: array[Puyo, Natural]
    puyoNums[Cell.GARBAGE] = nazo.env.garbageNum
    for color in ColorPuyo:
      puyoNums[color] = Natural nazo.env.colorNum color
    result.puyoNums = some puyoNums
  else:
    result.puyoNum = some Natural nazo.env.colorNum RequirementColorToCell[nazo.req.color.get]

func isAccepted*(node: Node): bool {.inline.} =
  ## Returns whether the node is accepted or not.
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

func filter4(num: int): int {.inline.} = num * (num >= 4).int

func canPrune*(node: Node): bool {.inline.} =
  ## Returns whether the node is unsolvable.
  if node.nazo.env.field.isDead:
    return true

  if node.fieldNum.isSome:
    if node.puyoNum.isSome:
      if node.puyoNum.get in 1 .. 3:
        return true
    else:
      if node.puyoNums.get[ColorPuyo.low .. ColorPuyo.high].anyIt it in 1 .. 3:
        return true

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

func isLeaf*(node: Node): bool {.inline.} =
  ## Returns whether the node is bottom (all moves are completed).
  node.positions.len == node.nazo.moveNum

func child*(node: Node, pos: Position): Node {.inline.} =
  ## Make the child of node with the position.
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
      env.moveWithRoughTracking
    elif node.nazo.req.kind in {
      DISAPPEAR_COLOR_SAMETIME, DISAPPEAR_COLOR_MORE_SAMETIME, DISAPPEAR_NUM_SAMETIME, DISAPPEAR_NUM_MORE_SAMETIME
    }:
      env.moveWithDetailTracking
    else:
      env.moveWithFullTracking
  
  result = node
  result.positions.add pos.some

  let
    pair = result.nazo.env.pairs.peekFirst
    moveResult = result.nazo.env.moveFn pos

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

  if node.puyoNum.isSome:
    result.puyoNum =
      some node.puyoNum.get.pred moveResult.totalDisappearNums.get[RequirementColorToCell[node.nazo.req.color.get]]
  else:
    var puyoNums: array[Puyo, Natural]
    for puyo in Puyo:
      puyoNums[puyo] = node.puyoNums.get[puyo].pred moveResult.totalDisappearNums.get[puyo]
    result.puyoNums = some puyoNums

func children*(node: Node): seq[Node] {.inline.} =
  ## Returns children of the node.
  collect:
    for pos in (
      if node.nazo.env.pairs.peekFirst.isDouble: node.nazo.env.field.validDoublePositions
      else: node.nazo.env.field.validPositions
    ):
      node.child pos
