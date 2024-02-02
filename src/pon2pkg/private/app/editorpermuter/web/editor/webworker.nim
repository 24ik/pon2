## This module implements procedures that use web workers.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[dom, options, sequtils, strutils, sugar, uri]
import ../../../../[webworker]
import ../../../../nazopuyo/[node, permute]
import ../../../../../corepkg/[field, misc, pair, position]
import ../../../../../nazopuyopkg/[nazopuyo]

type TaskKind* = enum
  ## Worker task kind.
  Solve = "solve"
  Permute = "permute"

# ------------------------------------------------
# Solve (async)
# ------------------------------------------------

const WaitLoopIntervalMs = 50

proc asyncSolve[F: TsuField or WaterField](
    nazo: NazoPuyo[F], results: var seq[Option[seq[Positions]]],
    reqKind: static RequirementKind, reqColor: static RequirementColor,
    earlyStopping: static bool, parallelCount: Positive) {.inline.} =
  ## Solves the nazo puyo.
  ## Solve results will be stored in `results`.
  if not nazo.requirement.isSupported or nazo.moveCount == 0:
    results = @[some newSeq[Positions](0)]
    return

  let rootNode = nazo.initNode
  if rootNode.canPrune(reqKind, reqColor):
    results = @[some newSeq[Positions](0)]
    return

  let childNodes = rootNode.children(reqKind, reqColor)
  results = newSeqOfCap[Option[seq[Positions]]](childNodes.len.succ)
  results.add none seq[Positions] # HACK: represent incompletion

  # result-register handler
  var interval: Interval
  proc handler(returnCode: WorkerReturnCode, messages: seq[string]) =
    case returnCode
    of Success:
      results.add some messages.mapIt it.parsePositions Izumiya
      if results.len == childNodes.len.succ:
        results.del 0
        interval.clearInterval
    of Failure:
      discard

  # setup workers
  var workers = collect:
    for _ in 1..parallelCount:
      initWorker()
  for worker in workers.mitems:
    worker.completeHandler = handler

  # run workers
  var childIdx = 0
  proc runWorkers =
    for worker in workers.mitems:
      if childIdx >= childNodes.len:
        break
      if worker.running:
        continue

      worker.run $Solve, $nazo.environment.field.rule,
        childNodes[childIdx].toStr
      childIdx.inc
  interval = runWorkers.setInterval WaitLoopIntervalMs

proc asyncSolve[F: TsuField or WaterField](
    nazo: NazoPuyo[F], results: var seq[Option[seq[Positions]]],
    reqKind: static RequirementKind, earlyStopping: static bool,
    parallelCount: Positive) {.inline.} =
  ## Solves the nazo puyo.
  ## Solve results will be stored in `results`.
  assert reqKind in {
    RequirementKind.Clear, DisappearCount, DisappearCountMore, ChainClear,
    ChainMoreClear, DisappearCountSametime, DisappearCountMoreSametime,
    DisappearPlace, DisappearPlaceMore, DisappearConnect, DisappearConnectMore}

  case nazo.requirement.color.get
  of RequirementColor.All:
    nazo.asyncSolve results, reqKind, RequirementColor.All, earlyStopping,
      parallelCount
  of RequirementColor.Red:
    nazo.asyncSolve results, reqKind, RequirementColor.Red, earlyStopping,
      parallelCount
  of RequirementColor.Green:
    nazo.asyncSolve results, reqKind, RequirementColor.Green, earlyStopping,
      parallelCount
  of RequirementColor.Blue:
    nazo.asyncSolve results, reqKind, RequirementColor.Blue, earlyStopping,
      parallelCount
  of RequirementColor.Yellow:
    nazo.asyncSolve results, reqKind, RequirementColor.Yellow, earlyStopping,
      parallelCount
  of RequirementColor.Purple:
    nazo.asyncSolve results, reqKind, RequirementColor.Purple, earlyStopping,
      parallelCount
  of RequirementColor.Garbage:
    nazo.asyncSolve results, reqKind, RequirementColor.Garbage, earlyStopping,
      parallelCount
  of RequirementColor.Color:
    nazo.asyncSolve results, reqKind, RequirementColor.Color, earlyStopping,
      parallelCount

proc asyncSolve*[F: TsuField or WaterField](
    nazo: NazoPuyo[F], results: var seq[Option[seq[Positions]]],
    showProgress = false, earlyStopping: static bool = false,
    parallelCount: Positive = 6) {.inline.} =
  ## Solves the nazo puyo.
  ## Solve results will be stored in `results`.
  const DummyColor = RequirementColor.All

  case nazo.requirement.kind
  of RequirementKind.Clear:
    nazo.asyncSolve results, RequirementKind.Clear, earlyStopping, parallelCount
  of DisappearColor:
    nazo.asyncSolve results, DisappearColor, DummyColor, earlyStopping,
      parallelCount
  of DisappearColorMore:
    nazo.asyncSolve results, DisappearColorMore, DummyColor, earlyStopping,
      parallelCount
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
    nazo.asyncSolve results, DisappearColorSametime, DummyColor, earlyStopping,
      parallelCount
  of DisappearColorMoreSametime:
    nazo.asyncSolve results, DisappearColorMoreSametime, DummyColor,
      earlyStopping, parallelCount
  of DisappearCountSametime:
    nazo.asyncSolve results, DisappearCountSametime, earlyStopping,
      parallelCount
  of DisappearCountMoreSametime:
    nazo.asyncSolve results, DisappearCountMoreSametime, earlyStopping,
      parallelCount
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
    results: var seq[Option[tuple[pairs: Pairs, answer: Positions]]],
    fixMoves: seq[Positive], allowDouble: bool, allowLastDouble: bool,
    parallelCount: Positive = 6) {.inline.} =
  ## Permutes the pairs.
  ## Results will be stored in `results`.
  let pairsSeq = nazo.allPairsSeq(fixMoves, allowDouble, allowLastDouble)
  results = newSeqOfCap[Option[tuple[pairs: Pairs, answer: Positions]]](
    pairsSeq.len.succ)
  results.add none tuple[pairs: Pairs, answer: Positions]

  # result-register handler
  var interval: Interval
  proc handler(returnCode: WorkerReturnCode, messages: seq[string]) =
    case returnCode
    of Success:
      if messages[0].parseBool:
        results.add some (pairs: pairsSeq[messages[1].parseInt],
                          answer: messages[2].parsePositions Izumiya)
      else:
        results.add none tuple[pairs: Pairs, answer: Positions]

      if results.len == pairsSeq.len.succ:
        results.keepItIf it.isSome
        interval.clearInterval
    of Failure:
      discard

  # setup workers
  var workers = collect:
    for _ in 1..parallelCount:
      initWorker()
  for worker in workers.mitems:
    worker.completeHandler = handler

  # run workers
  var pairsIdx = 0
  proc runWorkers =
    for worker in workers.mitems:
      if pairsIdx >= pairsSeq.len:
        break
      if worker.running:
        continue

      var nazo2 = nazo
      nazo2.environment.pairs = pairsSeq[pairsIdx]
      worker.run $Permute, $pairsIdx, $nazo2.toUri
      pairsIdx.inc
  interval = runWorkers.setInterval WaitLoopIntervalMs
