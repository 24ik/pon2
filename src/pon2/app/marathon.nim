## This module implements Puyo Puyo marathon.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, sugar, random]
import ./[key, simulator]
import ../[core]
import ../private/[algorithm, arrayutils, assign, critbits, setutils, strutils]

export core, simulator

type Marathon* = object ## Marathon manager.
  simulator*: Simulator

  matchQueries: seq[string]
  allQueries: seq[string]

  isReady*: bool
  critBitTree: CritBitTree[void]
  rng: Rand

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func load*(self: var Marathon, queries: openArray[string]) =
  ## Loads steps data.
  if self.isReady:
    return

  for query in queries:
    self.critBitTree.incl query
  self.allQueries &= queries

func init*(T: type Marathon, rng: Rand, queries: openArray[string] = []): T =
  var marathon = T(
    simulator: Simulator.init,
    matchQueries: @[],
    allQueries: @[],
    isReady: false,
    critBitTree: CritBitTree[void].default,
    rng: rng,
  )

  marathon.load queries

  marathon

# ------------------------------------------------
# Property
# ------------------------------------------------

func matchQueryCount*(self: Marathon): int =
  ## Returns the number of the matched queries.
  if self.isReady: self.matchQueries.len else: 0

func allQueryCount*(self: Marathon): int =
  ## Returns the number of the all queries.
  if self.isReady: self.allQueries.len else: 0

# ------------------------------------------------
# Match
# ------------------------------------------------

func swappedPrefixes(prefix: string): seq[string] =
  ## Returns all prefixes with all pairs swapped.
  var
    lastIndices = 6.initArrayWith 0 # AB, AC, AD, BC, BD, CD
    counts = 10.initArrayWith 0 # AB, AC, AD, BC, BD, CD, AA, BB, CC, DD
  for charIndex in countup(0, prefix.len - 1, 2):
    case prefix[charIndex .. charIndex + 1]
    of "AB", "BA":
      counts[0] += 1
      lastIndices[0].assign charIndex
    of "AC", "CA":
      counts[1] += 1
      lastIndices[1].assign charIndex
    of "AD", "DA":
      counts[2] += 1
      lastIndices[2].assign charIndex
    of "BC", "CB":
      counts[3] += 1
      lastIndices[3].assign charIndex
    of "BD", "DB":
      counts[4] += 1
      lastIndices[4].assign charIndex
    of "CD", "DC":
      counts[5] += 1
      lastIndices[5].assign charIndex
    of "AA":
      counts[6] += 1
    of "BB":
      counts[7] += 1
    of "CC":
      counts[8] += 1
    of "DD":
      counts[9] += 1

  # If a non-double pair (e.g. AB) exists and cells in the pair (e.g. A and B) only
  # appear in it, one of them is not need to swap.
  let
    countAbAc = counts[0] + counts[1]
    countAbAd = counts[0] + counts[2]
    countAcAd = counts[1] + counts[2]
    countBcBd = counts[3] + counts[4]
    countBcCd = counts[3] + counts[5]
    countBdCd = counts[4] + counts[5]
  var fixIndices = newSeqOfCap[int](2)
  if counts[0] > 0 and countAcAd + countBcBd + (counts[6] + counts[7]) == 0: # AB
    fixIndices.add lastIndices[0]
  if counts[1] > 0 and countAbAd + countBcCd + (counts[6] + counts[8]) == 0: # AC
    fixIndices.add lastIndices[1]
  if counts[2] > 0 and countAbAc + countBdCd + (counts[6] + counts[9]) == 0: # AD
    fixIndices.add lastIndices[2]
  if counts[3] > 0 and countAbAc + countBdCd + (counts[7] + counts[8]) == 0: # BC
    fixIndices.add lastIndices[3]
  if counts[4] > 0 and countAbAd + countBcCd + (counts[7] + counts[9]) == 0: # BD
    fixIndices.add lastIndices[4]
  if counts[5] > 0 and countAcAd + countBcBd + (counts[8] + counts[9]) == 0: # CD
    fixIndices.add lastIndices[5]

  let pairsSeq = collect:
    for charIndex in countup(0, prefix.len - 1, 2):
      let
        c1 = prefix[charIndex]
        c2 = prefix[charIndex + 1]

      if c1 == c2 or charIndex in fixIndices:
        @[c1 & c2]
      else:
        @[c1 & c2, c2 & c1]
  pairsSeq.product.mapIt it.join

func initReplaceDataSeqArray(): array[4, seq[seq[(string, string)]]] =
  ## Returns `ReplaceDataSeqArray`.
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
  ReplaceDataSeqArray = initReplaceDataSeqArray()
  ReplaceNeedKeysArray = ["a".toSet, "ab".toSet, "abc".toSet, "abcd".toSet]

func match*(self: var Marathon, prefix: string) =
  ## Searches queries that have specified prefixes and sets them to the marathon
  ## manager.
  if not self.isReady:
    return

  if prefix == "":
    self.matchQueries.setLen 0
    return

  let chars = prefix.toSet
  if chars in ReplaceNeedKeysArray:
    if prefix.len mod 2 == 1:
      return

    # ref: https://sengiken.web.fc2.com/tsumo/
    let matchCountMax =
      case prefix.len
      of 2:
        45000 # AB
      of 4:
        11000 # ABAC
      of 6:
        2600 # ABABAC
      else:
        400 # ABABACBD
    self.matchQueries.assign newSeqOfCap[string](matchCountMax)
    for replaceData in ReplaceDataSeqArray[chars.card - 1]:
      for pre in prefix.toUpperAscii.swappedPrefixes:
        {.push warning[ProveInit]: off.}
        for query in self.critBitTree.itemsWithPrefix pre.multiReplace replaceData:
          self.matchQueries &= query
        {.pop.}
  else:
    # ref: https://sengiken.web.fc2.com/tsumo/
    let matchCountMax =
      case prefix.len
      of 1:
        14000 # R
      of 2:
        4300 # RR
      of 3:
        1500 # YYY
      else:
        410 # YYYY
    self.matchQueries.assign newSeqOfCap[string](matchCountMax)
    for query in self.critBitTree.itemsWithPrefix prefix:
      self.matchQueries &= query

{.pop.}

# ------------------------------------------------
# Simulator
# ------------------------------------------------

func loadSteps(self: var Marathon, query: string) =
  ## Applies the steps to the simulator.
  var steps = Steps.init query.len div 2
  for i in countup(0, query.len - 1, 2):
    (query[i + 1] & query[i]).parseStep(Pon2).isErrOr:
      steps.addLast value

  self.simulator.assign Simulator.init(
    PuyoPuyo.init(Field.init, steps), keyBindPattern = self.simulator.keyBindPattern
  )

func selectQuery*(self: var Marathon, index: int) =
  ## Applies the selected query to the simulator.
  if not self.isReady:
    return

  if index in 0 ..< self.matchQueries.len:
    self.loadSteps self.matchQueries[index]

func selectRandomQuery*(self: var Marathon, fromMatched = true) =
  ## Applies a random query to the simulator.
  if not self.isReady:
    return

  if fromMatched:
    if self.matchQueryCount > 0:
      self.loadSteps self.rng.sample self.matchQueries
  else:
    if self.allQueryCount > 0:
      self.loadSteps self.rng.sample self.allQueries

# ------------------------------------------------
# Key
# ------------------------------------------------

proc operate*(self: var Marathon, key: KeyEvent): bool {.discardable.} =
  ## Performs an action specified by the key.
  ## Returns `true` if the key is handled.
  if key == KeyEventEnter:
    self.selectRandomQuery
    return true
  if key == KeyEventShiftEnter:
    self.selectRandomQuery(fromMatched = false)
    return true

  return self.simulator.operate key
