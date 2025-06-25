## This module implements procedures that use web workers.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[deques, dom, options, strutils, sugar, uri]
import ../../[solve]
import ../../../[webworker]
import
  ../../../../core/
    [field, fqdn, nazopuyo, pair, pairposition, position, puyopuyo, requirement]

type TaskKind* = enum
  ## Worker task kind.
  Solve = "solve"
  Permute = "permute"

# ------------------------------------------------
# Solve (async)
# ------------------------------------------------

const WaitLoopIntervalMs = 50

func parseAnswers(messages: seq[string]): seq[SolveAnswer] {.inline.} =
  ## Returns the answers converted from the messages.
  result = newSeqOfCap[SolveAnswer](messages[0].parseInt)
  let firstPos = messages[1].parsePosition

  var idx = 2
  while idx < messages.len:
    let answerLen = messages[idx].parseInt
    idx.inc

    {.push warning[Uninit]: off.}
    var answer = initDeque[Position](answerLen.succ)
    {.pop.}
    answer.addFirst firstPos
    for _ in 1 .. answerLen:
      answer.addLast messages[idx].parsePosition
      idx.inc

    result.add answer

  assert idx == messages.len

proc asyncSolve[F: TsuField or WaterField](
    nazo: NazoPuyo[F],
    results: ref seq[seq[SolveAnswer]],
    reqKind: static RequirementKind,
    reqColor: static RequirementColor,
    earlyStopping: static bool,
    parallelCount: Positive,
) {.inline.} =
  ## Solves the nazo puyo.
  ## Solve results are stored in `results`.
  let
    rootNode = nazo.initNode
    childNodes = rootNode.children(reqKind, reqColor)

  if not nazo.requirement.isSupported or nazo.moveCount == 0 or
      rootNode.canPrune(reqKind, reqColor):
    results[] = collect:
      for _ in 1 .. childNodes.len:
        newSeq[SolveAnswer](0)
    return

  results[] = newSeqOfCap[seq[SolveAnswer]](childNodes.len)

  # result-register handler
  var interval: Interval
  proc handler(returnCode: WorkerReturnCode, messages: seq[string]) =
    case returnCode
    of Success:
      results[].add messages.parseAnswers

      if results[].len == childNodes.len:
        interval.clearInterval
    of Failure:
      discard

  # setup workers
  let workers = new seq[Worker]
  workers[] = newSeqOfCap[Worker](parallelCount)
  for _ in 1 .. parallelCount:
    let worker = newWorker()
    worker.completeHandler = handler
    workers[].add worker

  # run workers
  var childIdx = 0
  proc runWorkers() =
    for worker in workers[]:
      if childIdx >= childNodes.len:
        break
      if worker.running:
        continue

      let (child, pos) = childNodes[childIdx]
      worker.run $Solve, $nazo.rule, $nazo.moveCount, $pos, child.toStr
      childIdx.inc

  interval = runWorkers.setInterval WaitLoopIntervalMs

proc asyncSolve[F: TsuField or WaterField](
    nazo: NazoPuyo[F],
    results: ref seq[seq[SolveAnswer]],
    reqKind: static RequirementKind,
    earlyStopping: static bool,
    parallelCount: Positive,
) {.inline.} =
  ## Solves the nazo puyo.
  ## Solve results are stored in `results`.
  assert reqKind in {
    RequirementKind.Clear, DisappearCount, DisappearCountMore, ChainClear,
    ChainMoreClear, DisappearCountSametime, DisappearCountMoreSametime, DisappearPlace,
    DisappearPlaceMore, DisappearConnect, DisappearConnectMore,
  }

  case nazo.requirement.color
  of RequirementColor.All:
    nazo.asyncSolve results, reqKind, RequirementColor.All, earlyStopping, parallelCount
  of RequirementColor.Red:
    nazo.asyncSolve results, reqKind, RequirementColor.Red, earlyStopping, parallelCount
  of RequirementColor.Green:
    nazo.asyncSolve results,
      reqKind, RequirementColor.Green, earlyStopping, parallelCount
  of RequirementColor.Blue:
    nazo.asyncSolve results,
      reqKind, RequirementColor.Blue, earlyStopping, parallelCount
  of RequirementColor.Yellow:
    nazo.asyncSolve results,
      reqKind, RequirementColor.Yellow, earlyStopping, parallelCount
  of RequirementColor.Purple:
    nazo.asyncSolve results,
      reqKind, RequirementColor.Purple, earlyStopping, parallelCount
  of RequirementColor.Garbage:
    nazo.asyncSolve results,
      reqKind, RequirementColor.Garbage, earlyStopping, parallelCount
  of RequirementColor.Color:
    nazo.asyncSolve results,
      reqKind, RequirementColor.Color, earlyStopping, parallelCount

proc asyncSolve*[F: TsuField or WaterField](
    nazo: NazoPuyo[F],
    results: ref seq[seq[SolveAnswer]],
    showProgress = false,
    earlyStopping: static bool = false,
    parallelCount: Positive = 6,
) {.inline.} =
  ## Solves the nazo puyo.
  ## Solve results are stored in `results`.
  const DummyColor = RequirementColor.All

  case nazo.requirement.kind
  of RequirementKind.Clear:
    nazo.asyncSolve results, RequirementKind.Clear, earlyStopping, parallelCount
  of DisappearColor:
    nazo.asyncSolve results, DisappearColor, DummyColor, earlyStopping, parallelCount
  of DisappearColorMore:
    nazo.asyncSolve results,
      DisappearColorMore, DummyColor, earlyStopping, parallelCount
  of DisappearCount:
    nazo.asyncSolve results, DisappearCount, earlyStopping, parallelCount
  of DisappearCountMore:
    nazo.asyncSolve results, DisappearCountMore, earlyStopping, parallelCount
  of Chain:
    nazo.asyncSolve results, Chain, DummyColor, earlyStopping, parallelCount
  of ChainMore:
    nazo.asyncSolve results, ChainMore, DummyColor, earlyStopping, parallelCount
  of ChainClear:
    nazo.asyncSolve results, ChainClear, earlyStopping, parallelCount
  of ChainMoreClear:
    nazo.asyncSolve results, ChainMoreClear, earlyStopping, parallelCount
  of DisappearColorSametime:
    nazo.asyncSolve results,
      DisappearColorSametime, DummyColor, earlyStopping, parallelCount
  of DisappearColorMoreSametime:
    nazo.asyncSolve results,
      DisappearColorMoreSametime, DummyColor, earlyStopping, parallelCount
  of DisappearCountSametime:
    nazo.asyncSolve results, DisappearCountSametime, earlyStopping, parallelCount
  of DisappearCountMoreSametime:
    nazo.asyncSolve results, DisappearCountMoreSametime, earlyStopping, parallelCount
  of DisappearPlace:
    nazo.asyncSolve results, DisappearPlace, earlyStopping, parallelCount
  of DisappearPlaceMore:
    nazo.asyncSolve results, DisappearPlaceMore, earlyStopping, parallelCount
  of DisappearConnect:
    nazo.asyncSolve results, DisappearConnect, earlyStopping, parallelCount
  of DisappearConnectMore:
    nazo.asyncSolve results, DisappearConnectMore, earlyStopping, parallelCount

# ------------------------------------------------
# Permute (async)
# ------------------------------------------------

proc asyncPermute*[F: TsuField or WaterField](
    nazo: NazoPuyo[F],
    results: ref seq[Option[PairsPositions]],
    pairsPositionsSeq: seq[PairsPositions],
    fixMoves: seq[Positive],
    allowDouble: bool,
    allowLastDouble: bool,
    parallelCount: Positive = 6,
) {.inline.} =
  ## Permutes the pairs.
  ## Results are stored in `results`.
  results[] = newSeqOfCap[Option[PairsPositions]](pairsPositionsSeq.len)

  # result-register handler
  var interval: Interval
  proc handler(returnCode: WorkerReturnCode, messages: seq[string]) =
    case returnCode
    of Success:
      if messages[0].parseBool:
        results[].add some messages[1].parsePairsPositions Pon2
      else:
        results[].add none PairsPositions

      if results[].len == pairsPositionsSeq.len:
        interval.clearInterval
    of Failure:
      discard

  # setup workers
  let workers = new seq[Worker]
  workers[] = newSeqOfCap[Worker](parallelCount)
  for _ in 1 .. parallelCount:
    let worker = newWorker()
    worker.completeHandler = handler
    workers[].add worker

  # run workers
  var pairsPositionsIdx = 0
  proc runWorkers() =
    for worker in workers[]:
      if pairsPositionsIdx >= pairsPositionsSeq.len:
        break
      if worker.running:
        continue

      var nazo2 = nazo
      nazo2.puyoPuyo.pairsPositions = pairsPositionsSeq[pairsPositionsIdx]
      worker.run $Permute, $nazo2.toUriQuery, $nazo2.puyoPuyo.field.rule
      pairsPositionsIdx.inc

  interval = runWorkers.setInterval WaitLoopIntervalMs
