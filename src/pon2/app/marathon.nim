## This module implements Puyo Puyo marathon.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, sugar, random]
import ./[nazopuyowrap, simulator]
import ../[core]
import ../private/[arrayops2, assign3, critbits2, results2, strutils2, utils]

when defined(js) or defined(nimsuggest):
  import std/[dom]
when not defined(js):
  import chronos

type Marathon* = object ## Marathon manager.
  simulator: Simulator
  matchQueries: seq[string]

  dataLoaded: bool
  allQueries: seq[string]
  critBitTree: CritBitTree[void]

  rng: Rand

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type Marathon, rng: Rand): T {.inline.} =
  T(
    simulator: Simulator.init PuyoPuyo[TsuField].init,
    matchQueries: @[],
    dataLoaded: false,
    allQueries: @[],
    critBitTree: CritBitTree[void].default,
    rng: rng,
  )

# ------------------------------------------------
# Load
# ------------------------------------------------

func load*(self: var Marathon, allQueries: seq[string]) {.inline.} =
  ## Loads steps data.
  self.allQueries.assign allQueries
  self.critBitTree.assign allQueries.toCritBitTree2
  self.dataLoaded.assign true

{.push warning[Uninit]: off.}
proc asyncLoad*(self: ref Marathon, allQueries: seq[string]) {.inline, async.} =
  ## Loads steps data asynchronously.
  await sleepZeroAsync()
  self[].load allQueries

{.pop.}

# ------------------------------------------------
# Property
# ------------------------------------------------

func dataLoaded*(self: Marathon): bool {.inline.} =
  ## Returns `true` if steps data are loaded.
  self.dataLoaded

func matchQueries*(self: Marathon): seq[string] {.inline.} =
  ## Returns matched queries.
  self.matchQueries

func simulator*(self: Marathon): Simulator {.inline.} =
  ## Returns the simulator.
  self.simulator

func simulator*(self: var Marathon): var Simulator {.inline.} =
  ## Returns the simulator.
  self.simulator

# ------------------------------------------------
# Match
# ------------------------------------------------

func swappedPrefixes(prefix: string): seq[string] {.inline.} =
  ## Returns all prefixes with all pairs swapped.
  var
    lastIndices = initArrWith(6, 0) # AB, AC, AD, BC, BD, CD
    cnts = initArrWith(10, 0) # AB, AC, AD, BC, BD, CD, AA, BB, CC, DD
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

func initReplaceDataSeqArr(): array[4, seq[seq[(string, string)]]] {.inline.} =
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

func match*(self: var Marathon, prefix: string) {.inline.} =
  ## Searches queries that have specified prefixes and sets them to the marathon
  ## manager.
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

{.push warning[Uninit]: off.}
proc asyncMatch*(self: ref Marathon, prefix: string) {.inline, async.} =
  ## Searches for queries that have specified prefixes and sets them to the marathon
  ## manager asynchronously.
  await sleepZeroAsync()
  self[].match prefix

{.pop.}

# ------------------------------------------------
# Simulator
# ------------------------------------------------

func loadSteps(self: var Marathon, query: string) {.inline.} =
  ## Applies the steps to the simulator.
  let stepsRes = query.parseSteps Pon2
  if stepsRes.isErr:
    return

  self.simulator.assign Simulator.init PuyoPuyo[TsuField].init(
    TsuField.init, stepsRes.unsafeValue
  )

func selectQuery*(self: var Marathon, idx: int) {.inline.} =
  ## Applies the selected query to the simulator.
  if idx < self.matchQueries.len:
    self.loadSteps self.matchQueries[idx]

func selectRandomQuery*(self: var Marathon, fromMatched = true) {.inline.} =
  ## Applies a random query to the simulator.
  if fromMatched:
    if self.matchQueries.len > 0:
      self.loadSteps self.rng.sample self.matchQueries
  else:
    if self.dataLoaded:
      self.loadSteps self.rng.sample self.allQueries
