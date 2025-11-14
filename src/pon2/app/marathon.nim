## This module implements Puyo Puyo marathon.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, sugar, random]
import ./[key, nazopuyowrap, simulator]
import ../[core]
import ../private/[arrayutils, assign, critbits2, results2, strutils2, utils]

export simulator

type Marathon* = object ## Marathon manager.
  simulator: Simulator

  matchQueries: seq[string]
  allQueries: seq[string]

  isReady: bool
  critBitTree: CritBitTree[void]
  rng: Rand

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func load*(self: var Marathon, queries: openArray[string], isReady = false) =
  ## Loads steps data.
  if self.isReady:
    return

  for query in queries:
    self.critBitTree.incl query
  self.allQueries &= queries

  if isReady:
    self.isReady.assign true

func init*(
    T: type Marathon, rng: Rand, queries: openArray[string] = [], isReady = false
): T =
  var marathon = T(
    simulator: Simulator.init PuyoPuyo[TsuField].init,
    matchQueries: @[],
    allQueries: @[],
    isReady: false,
    critBitTree: CritBitTree[void].default,
    rng: rng,
  )
  marathon.load queries, isReady
  marathon

# ------------------------------------------------
# Property
# ------------------------------------------------

func simulator*(self: Marathon): Simulator =
  ## Returns the simulator.
  self.simulator

func simulator*(self: var Marathon): var Simulator =
  ## Returns the simulator.
  self.simulator

func isReady*(self: Marathon): bool =
  ## Returns `true` if the marathon manager is ready.
  self.isReady

func `isReady=`*(self: var Marathon, isReady: bool) =
  self.isReady.assign self.isReady or isReady

func matchQueryCnt*(self: Marathon): int =
  ## Returns the number of the matched queries.
  if self.isReady: self.matchQueries.len else: 0

func allQueryCnt*(self: Marathon): int =
  ## Returns the number of the all queries.
  if self.isReady: self.allQueries.len else: 0

# ------------------------------------------------
# Match
# ------------------------------------------------

func swappedPrefixes(prefix: string): seq[string] =
  ## Returns all prefixes with all pairs swapped.
  var
    lastIndices = 6.initArrayWith 0 # AB, AC, AD, BC, BD, CD
    cnts = 10.initArrayWith 0 # AB, AC, AD, BC, BD, CD, AA, BB, CC, DD
  for charIdx in countup(0, prefix.len.pred, 2):
    case prefix[charIdx .. charIdx.succ]
    of "AB", "BA":
      cnts[0].inc
      lastIndices[0].assign charIdx
    of "AC", "CA":
      cnts[1].inc
      lastIndices[1].assign charIdx
    of "AD", "DA":
      cnts[2].inc
      lastIndices[2].assign charIdx
    of "BC", "CB":
      cnts[3].inc
      lastIndices[3].assign charIdx
    of "BD", "DB":
      cnts[4].inc
      lastIndices[4].assign charIdx
    of "CD", "DC":
      cnts[5].inc
      lastIndices[5].assign charIdx
    of "AA":
      cnts[6].inc
    of "BB":
      cnts[7].inc
    of "CC":
      cnts[8].inc
    of "DD":
      cnts[9].inc

  # If a non-double pair (e.g. AB) exists and cells in the pair (e.g. A and B) only
  # appear as the ones, one of them is not need to swap.
  let
    cntAbAc = cnts[0] + cnts[1]
    cntAbAd = cnts[0] + cnts[2]
    cntAcAd = cnts[1] + cnts[2]
    cntBcBd = cnts[3] + cnts[4]
    cntBcCd = cnts[3] + cnts[5]
    cntBdCd = cnts[4] + cnts[5]
  var fixIndices = newSeqOfCap[int](2)
  if cnts[0] > 0 and cntAcAd + cntBcBd + (cnts[6] + cnts[7]) == 0: # AB
    fixIndices.add lastIndices[0]
  if cnts[1] > 0 and cntAbAd + cntBcCd + (cnts[6] + cnts[8]) == 0: # AC
    fixIndices.add lastIndices[1]
  if cnts[2] > 0 and cntAbAc + cntBdCd + (cnts[6] + cnts[9]) == 0: # AD
    fixIndices.add lastIndices[2]
  if cnts[3] > 0 and cntAbAc + cntBdCd + (cnts[7] + cnts[8]) == 0: # BC
    fixIndices.add lastIndices[3]
  if cnts[4] > 0 and cntAbAd + cntBcCd + (cnts[7] + cnts[9]) == 0: # BD
    fixIndices.add lastIndices[4]
  if cnts[5] > 0 and cntAcAd + cntBcBd + (cnts[8] + cnts[9]) == 0: # CD
    fixIndices.add lastIndices[5]

  let pairsSeq = collect:
    for charIdx in countup(0, prefix.len.pred, 2):
      let
        c1 = prefix[charIdx]
        c2 = prefix[charIdx.succ]

      if c1 == c2 or charIdx in fixIndices:
        @[c1 & c2]
      else:
        @[c1 & c2, c2 & c1]
  pairsSeq.product2.mapIt it.join

func initReplaceDataSeqArr(): array[4, seq[seq[(string, string)]]] =
  ## Returns `ReplaceDataSeqArr`.
  let
    replaceDataSeq1 = collect:
      for c0 in Cell.Red .. Cell.Purple:
        @[("A", $c0)]
    replaceDataSeq2 = collect:
      for c0 in Cell.Red .. Cell.Purple:
        for c1 in Cell.Red .. Cell.Purple:
          if c0 != c1:
            @[("A", $c0), ("B", $c1)]
    replaceDataSeq3 = collect:
      for c0 in Cell.Red .. Cell.Purple:
        for c1 in Cell.Red .. Cell.Purple:
          for c2 in Cell.Red .. Cell.Purple:
            if {c0, c1, c2}.card == 3:
              @[("A", $c0), ("B", $c1), ("C", $c2)]
    replaceDataSeq4 = collect:
      for c0 in Cell.Red .. Cell.Purple:
        for c1 in Cell.Red .. Cell.Purple:
          for c2 in Cell.Red .. Cell.Purple:
            for c3 in Cell.Red .. Cell.Purple:
              if {c0, c1, c2, c3}.card == 4:
                @[("A", $c0), ("B", $c1), ("C", $c2), ("D", $c3)]

  [replaceDataSeq1, replaceDataSeq2, replaceDataSeq3, replaceDataSeq4]

const
  ReplaceDataSeqArr = initReplaceDataSeqArr()
  ReplaceNeedKeysArr = ["a".toSet2, "ab".toSet2, "abc".toSet2, "abcd".toSet2]

func match*(self: var Marathon, prefix: string) =
  ## Searches queries that have specified prefixes and sets them to the marathon
  ## manager.
  if not self.isReady:
    return

  if prefix == "":
    self.matchQueries.setLen 0
    return

  let chars = prefix.toSet2
  if chars in ReplaceNeedKeysArr:
    if prefix.len mod 2 == 1:
      return

    # ref: https://sengiken.web.fc2.com/tsumo/
    let matchCntMax =
      case prefix.len
      of 2:
        45000 # AB
      of 4:
        11000 # ABAC
      of 6:
        2600 # ABABAC
      else:
        400 # ABABACBD
    self.matchQueries.assign newSeqOfCap[string](matchCntMax)
    for replaceData in ReplaceDataSeqArr[chars.card.pred]:
      for pre in prefix.toUpperAscii.swappedPrefixes:
        {.push warning[ProveInit]: off.}
        for query in self.critBitTree.itemsWithPrefix pre.multiReplace replaceData:
          self.matchQueries &= query
        {.pop.}
  else:
    # ref: https://sengiken.web.fc2.com/tsumo/
    let matchCntMax =
      case prefix.len
      of 1:
        14000 # R
      of 2:
        4300 # RR
      of 3:
        1500 # YYY
      else:
        410 # YYYY
    self.matchQueries.assign newSeqOfCap[string](matchCntMax)
    for query in self.critBitTree.itemsWithPrefix prefix:
      self.matchQueries &= query

{.pop.}

# ------------------------------------------------
# Simulator
# ------------------------------------------------

func loadSteps(self: var Marathon, query: string) =
  ## Applies the steps to the simulator.
  var steps = initDeque[Step](query.len div 2)
  for i in countup(0, query.len.pred, 2):
    (query[i.succ] & query[i]).parseStep(Pon2).isErrOr:
      steps.addLast value

  self.simulator.assign Simulator.init PuyoPuyo[TsuField].init(TsuField.init, steps)

func selectQuery*(self: var Marathon, idx: int) =
  ## Applies the selected query to the simulator.
  if not self.isReady:
    return

  if idx in 0 ..< self.matchQueries.len:
    self.loadSteps self.matchQueries[idx]

func selectRandomQuery*(self: var Marathon, fromMatched = true) =
  ## Applies a random query to the simulator.
  if not self.isReady:
    return

  if fromMatched:
    if self.matchQueryCnt > 0:
      self.loadSteps self.rng.sample self.matchQueries
  else:
    if self.allQueryCnt > 0:
      self.loadSteps self.rng.sample self.allQueries

# ------------------------------------------------
# Keyboard
# ------------------------------------------------

proc operate*(self: var Marathon, key: KeyEvent): bool {.discardable.} =
  ## Performs an action specified by the key.
  ## Returns `true` if the key is handled.
  if key == static(KeyEvent.init "Enter"):
    self.selectRandomQuery
    return true
  if key == static(KeyEvent.init("Enter", shift = true)):
    self.selectRandomQuery(fromMatched = false)
    return true

  return self.simulator.operate key
