## This module implements the Nazo Puyo Grimoire.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, sets, sugar]
import ./[simulator]
import ../[core]
import ../private/[algorithm, arrayutils, assign, setutils, suffixarray, tables]
import ../private/app/[grimoire]

type
  GrimoireEntry* = object ## Entry of the Nazo Puyo Grimoire.
    query*: string
    moveCount*: int
    goal*: Goal
    title*: string
    creators*: seq[string]
    source*: string
    sourceDetail*: string

  Grimoire* = object ## Nazo Puyo Grimoire.
    simulator*: Simulator

    entries: seq[GrimoireEntry]
    matchedEntryIndices: set[int16]
    allIndices: set[int16]

    moveCountToIndices: seq[set[int16]]
    kindToIndices: array[GoalKind, set[int16]]
    noKindIndices: set[int16]
    hasClearColorToIndices: array[2, set[int16]]
    titleSuffixArray: SuffixArray
    titleIndexToIndices: seq[set[int16]]
    creatorSuffixArray: SuffixArray
    creatorIndexToIndices: seq[set[int16]]
    sourceSuffixArray: SuffixArray
    sourceIndexToIndices: seq[set[int16]]

    sortedSources: seq[string]
    isReady: bool

  GrimoireMatcher* = object ## Matcher of the Nazo Puyo Grimoire.
    moveCountOpt*: Opt[int]
    kindOptOpt*: Opt[Opt[GoalKind]]
    hasClearColorOpt*: Opt[bool]
    titleOpt*: Opt[string]
    creatorOpt*: Opt[string]
    sourceOpt*: Opt[string]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(
    T: type GrimoireEntry,
    query: string,
    title = "",
    creators = newSeq[string](),
    source = "",
    sourceDetail = "",
): T =
  let
    nazoPuyoResult = query.parseNazoPuyo Pon2
    moveCount: int
    goal: Goal
  if nazoPuyoResult.isOk:
    let nazoPuyo = nazoPuyoResult.unsafeValue
    moveCount = nazoPuyo.puyoPuyo.steps.len
    goal = nazoPuyo.goal
  else:
    moveCount = 0
    goal = Goal.init

  T(
    query: query,
    moveCount: moveCount,
    goal: goal,
    title: title,
    creators: creators,
    source: source,
    sourceDetail: sourceDetail,
  )

func add(self: var Grimoire, entry: GrimoireEntry) =
  ## Adds the entry to the grimoire.
  if self.isReady:
    return

  # load Nazo Puyo
  let nazoPuyoResult = entry.query.parseNazoPuyo Pon2
  if nazoPuyoResult.isErr:
    return
  let nazoPuyo = nazoPuyoResult.unsafeValue

  let entryIndex = self.entries.len.int16
  self.entries.add entry

  # moveCount
  let moveCount = nazoPuyo.puyoPuyo.steps.len
  if self.moveCountToIndices.len < moveCount + 1:
    self.moveCountToIndices.setLen moveCount + 1
  self.moveCountToIndices[moveCount].incl entryIndex

  # kind
  if nazoPuyo.goal.mainOpt.isOk:
    self.kindToIndices[nazoPuyo.goal.mainOpt.unsafeValue.kind].incl entryIndex
  else:
    self.noKindIndices.incl entryIndex

  # clear color
  self.hasClearColorToIndices[nazoPuyo.goal.clearColorOpt.isOk.int].incl entryIndex

func add*(self: var Grimoire, entries: openArray[GrimoireEntry]) =
  ## Adds the entries to the grimoire.
  for entry in entries:
    self.add entry

func init*(T: type Grimoire, entries: openArray[GrimoireEntry] = []): T =
  var grimoire = T(
    simulator: Simulator.init,
    entries: @[],
    matchedEntryIndices: set[int16]({}),
    allIndices: set[int16]({}),
    moveCountToIndices: @[],
    kindToIndices: GoalKind.initArrayWith set[int16]({}),
    noKindIndices: set[int16]({}),
    hasClearColorToIndices: 2.initArrayWith set[int16]({}),
    titleSuffixArray: SuffixArray.init newSeq[string](),
    titleIndexToIndices: @[],
    creatorSuffixArray: SuffixArray.init newSeq[string](),
    creatorIndexToIndices: @[],
    sourceSuffixArray: SuffixArray.init newSeq[string](),
    sourceIndexToIndices: @[],
    sortedSources: @[],
    isReady: false,
  )

  grimoire.add entries

  grimoire

func init*(
    T: type GrimoireMatcher,
    moveCountOpt = Opt[int].err,
    kindOptOpt = Opt[Opt[GoalKind]].err,
    hasClearColorOpt = Opt[bool].err,
    titleOpt = Opt[string].err,
    creatorOpt = Opt[string].err,
    sourceOpt = Opt[string].err,
): T =
  T(
    moveCountOpt: moveCountOpt,
    kindOptOpt: kindOptOpt,
    hasClearColorOpt: hasClearColorOpt,
    titleOpt: titleOpt.map (title: string) => title.normalized,
    creatorOpt: creatorOpt.map (creator: string) => creator.normalized,
    sourceOpt: sourceOpt.map (source: string) => source.normalized,
  )

# ------------------------------------------------
# Property
# ------------------------------------------------

func `[]`*(self: Grimoire, index: int): GrimoireEntry =
  self.entries[index]

func isReady*(self: Grimoire): bool =
  ## Returns `true` if the grimoire is ready.
  self.isReady

func `isReady=`*(self: var Grimoire, isReady: bool) =
  ## Performs the preprocessing of the grimoire and sets `isReady`.
  # prepare indices, sorted sources
  var
    titleToIndices = initTable[string, set[int16]]()
    creatorToIndices = initTable[string, set[int16]]()
    sourceToIndices = initTable[string, set[int16]]()
    sourcesSet = initHashSet[string]()
  for entryIndex, entry in self.entries:
    let entryIndex16 = entryIndex.int16

    if entry.title.len > 0:
      titleToIndices.mgetOrPut(entry.title.normalized, {}).incl entryIndex16
    for creator in entry.creators:
      creatorToIndices.mgetOrPut(creator.normalized, {}).incl entryIndex16
    if entry.source.len > 0:
      sourceToIndices.mgetOrPut(entry.source.normalized, {}).incl entryIndex16
      sourcesSet.incl entry.source

  # title
  let titleCount = titleToIndices.len
  var titles = newSeqOfCap[string](titleCount)
  self.titleIndexToIndices.assign newSeqOfCap[set[int16]](titleCount)
  for (title, indices) in titleToIndices.pairs:
    titles.add title
    self.titleIndexToIndices.add indices
  self.titleSuffixArray.assign SuffixArray.init titles

  # creator
  let creatorCount = creatorToIndices.len
  var creators = newSeqOfCap[string](creatorCount)
  self.creatorIndexToIndices.assign newSeqOfCap[set[int16]](creatorCount)
  for (creator, indices) in creatorToIndices.pairs:
    creators.add creator
    self.creatorIndexToIndices.add indices
  self.creatorSuffixArray.assign SuffixArray.init creators

  # source
  let sourceCount = sourceToIndices.len
  var sources = newSeqOfCap[string](sourceCount)
  self.sourceIndexToIndices.assign newSeqOfCap[set[int16]](sourceCount)
  for (source, indices) in sourceToIndices.pairs:
    sources.add source
    self.sourceIndexToIndices.add indices
  self.sourceSuffixArray.assign SuffixArray.init sources

  # sort source
  self.sortedSources.assign sourcesSet.toSeq.sorted

  # match all
  self.allIndices.assign (0'i16 ..< self.entries.len.int16).toSet
  self.matchedEntryIndices.assign self.allIndices

  self.isReady.assign isReady

func len*(self: Grimoire): int =
  ## Returns the number of the entries.
  self.entries.len

func matchedEntryIndices*(self: Grimoire): set[int16] =
  ## Returns the sorted indices of the matched entries.
  self.matchedEntryIndices

func moveCountMax*(self: Grimoire): int =
  ## Returns the max move count of the Nazo Puyo in the grimoire.
  self.moveCountToIndices.len - 1

func sources*(self: Grimoire): seq[string] =
  ## Returns the sorted sources.
  self.sortedSources

# ------------------------------------------------
# Match
# ------------------------------------------------

func match*(self: var Grimoire, matcher: GrimoireMatcher) =
  ## Searches by the matcher.
  if not self.isReady:
    return

  self.matchedEntryIndices.assign self.allIndices

  # move count
  if matcher.moveCountOpt.isOk:
    let moveCount = matcher.moveCountOpt.unsafeValue
    if moveCount in 0 ..< self.moveCountToIndices.len:
      self.matchedEntryIndices *= self.moveCountToIndices[moveCount]
    else:
      self.matchedEntryIndices.assign {}
      return

  # kind
  if matcher.kindOptOpt.isOk:
    let kindOpt = matcher.kindOptOpt.unsafeValue
    if kindOpt.isOk:
      self.matchedEntryIndices *= self.kindToIndices[kindOpt.unsafeValue]
    else:
      self.matchedEntryIndices *= self.noKindIndices

  # clear color
  if matcher.hasClearColorOpt.isOk:
    let hasClearColor = matcher.hasClearColorOpt.unsafeValue
    self.matchedEntryIndices *= self.hasClearColorToIndices[hasClearColor.int]

  # title
  if matcher.titleOpt.isOk:
    let title = matcher.titleOpt.unsafeValue

    var indices = set[int16]({})
    for titleIndex in self.titleSuffixArray.findAll title:
      indices += self.titleIndexToIndices[titleIndex]
    self.matchedEntryIndices *= indices

  # creator
  if matcher.creatorOpt.isOk:
    let creator = matcher.creatorOpt.unsafeValue

    var indices = set[int16]({})
    for creatorIndex in self.creatorSuffixArray.findAll creator:
      indices += self.creatorIndexToIndices[creatorIndex]
    self.matchedEntryIndices *= indices

  # source
  if matcher.sourceOpt.isOk:
    let source = matcher.sourceOpt.unsafeValue

    var indices = set[int16]({})
    for sourceIndex in self.sourceSuffixArray.findAll source:
      indices += self.sourceIndexToIndices[sourceIndex]
    self.matchedEntryIndices *= indices
