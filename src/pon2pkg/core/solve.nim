## This module implements a solver.
##

const
  singleThread {.booldefine.} = false
  SingleThread = singleThread or defined(js)

import deques
import options
import sequtils
import strutils
import strformat
import sugar
when not SingleThread:
  import threadpool

import nazopuyo_core
import puyo_core

import ./node

type
  Solution* = Positions
  Solutions* = seq[Solution]
  InspectSolutions* = tuple
    solutions: Solutions
    visitNodeNum: Positive

func `$`*(sol: Solution): string {.inline.} =
  let
    posStrs = collect:
      for pos in sol:
        $pos
    solStr = posStrs.join ", "

  return &"@[{solStr}]"

func solveRec(node: Node): Solutions {.inline.} =
  ## Solves the nazo puyo at the node recursively.
  if node.isAccepted:
    result.add node.positions
    return

  if node.isLeaf or node.canPrune:
    return

  for child in node.children:
    result &= child.solveRec

proc solve*(nazo: Nazo): Solutions {.inline.} =
  ## Solves the nazo puyo.
  if nazo.req.kind in {
    DISAPPEAR_PLACE, DISAPPEAR_PLACE_MORE, DISAPPEAR_CONNECT, DISAPPEAR_CONNECT_MORE
  } and nazo.req.color.get == RequirementColor.GARBAGE:
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
  ## Solves the nazo puyo represented by the url.
  let nazo = url.toNazo true
  if nazo.isNone:
    return

  let urls = collect:
    for sol in nazo.get.solve:
      nazo.get.toUrl sol.some, domain
  return some urls

func `&=`(sol: var InspectSolutions, other: InspectSolutions) {.inline.} =
  sol.solutions &= other.solutions
  sol.visitNodeNum.inc other.visitNodeNum

func inspectSolveRec(node: Node, earlyStopping: bool): InspectSolutions {.inline.} =
  ## Solves the nazo puyo at the node recursively, keeping the number of visited nodes.
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
  ## Solves the nazo puyo, keeping the number of visited nodes.
  if nazo.req.kind in {
    DISAPPEAR_PLACE, DISAPPEAR_PLACE_MORE, DISAPPEAR_CONNECT, DISAPPEAR_CONNECT_MORE
  } and nazo.req.color.get == RequirementColor.GARBAGE:
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
  ## Solves the nazo puyo represented by the url, keeping the number of visited nodes.
  let nazo = url.toNazo true
  if nazo.isNone:
    return

  let (solutions, visitNodeNum) = nazo.get.inspectSolve earlyStopping
  return some (urls: solutions.mapIt nazo.get.toUrl(it.some, domain), visitNodeNum: visitNodeNum.int)
