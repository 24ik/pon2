## This module implements the Nazo Puyo Grimoire.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, sets, strformat, sugar]
import ./[simulator]
import ../[core]
import ../private/[algorithm, arrayutils, assign, setutils, suffixarray, tables]
import ../private/app/[grimoire]

export utils

type
  GrimoireEntry* = object ## Entry of the Nazo Puyo Grimoire.
    id*: int16 ## `id` should be unique and non-negative
    query*: string
    rule*: Rule
    moveCount*: int
    goal*: Goal
    title*: string
    creators*: seq[string]
    source*: string
    sourceDetail*: string

  Grimoire* = object ## Nazo Puyo Grimoire.
    simulator*: Simulator

    entries: seq[GrimoireEntry]
    matchedEntryIds: set[int16]
    allIds: set[int16]

    ruleToIds: array[Rule, set[int16]]
    moveCountToIds: seq[set[int16]]
    kindToIds: array[GoalKind, set[int16]]
    noKindIds: set[int16]
    hasClearColorToIds: array[2, set[int16]]
    titleSuffixArray: SuffixArray
    titleIndexToIds: seq[set[int16]]
    creatorSuffixArray: SuffixArray
    creatorIndexToIds: seq[set[int16]]
    sourceSuffixArray: SuffixArray
    sourceIndexToIds: seq[set[int16]]

    idToIndex: seq[int]
    sortedSources: seq[string]
    isReady: bool

  GrimoireMatcher* = object ## Matcher of the Nazo Puyo Grimoire.
    ruleOpt*: Opt[Rule]
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
    id: int16,
    query: string,
    title = "",
    creators = newSeq[string](),
    source = "",
    sourceDetail = "",
): T =
  ## `id` should be unique and non-negative
  let
    nazoPuyoResult = query.parseNazoPuyo Pon2
    rule: Rule
    moveCount: int
    goal: Goal
  if nazoPuyoResult.isOk:
    let nazoPuyo = nazoPuyoResult.unsafeValue
    rule = nazoPuyo.puyoPuyo.field.rule
    moveCount = nazoPuyo.puyoPuyo.steps.len
    goal = nazoPuyo.goal
  else:
    moveCount = 0
    rule = Rule.low
    goal = Goal.init

  T(
    id: id,
    query: query,
    rule: rule,
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

  # entries
  self.entries.add entry

  # rule
  self.ruleToIds[nazoPuyo.puyoPuyo.field.rule].incl entry.id

  # moveCount
  let moveCount = nazoPuyo.puyoPuyo.steps.len
  if self.moveCountToIds.len < moveCount + 1:
    self.moveCountToIds.setLen moveCount + 1
  self.moveCountToIds[moveCount].incl entry.id

  # kind
  if nazoPuyo.goal.mainOpt.isOk:
    self.kindToIds[nazoPuyo.goal.mainOpt.unsafeValue.kind].incl entry.id
  else:
    self.noKindIds.incl entry.id

  # clear color
  self.hasClearColorToIds[nazoPuyo.goal.clearColorOpt.isOk.int].incl entry.id

func add*(self: var Grimoire, entries: openArray[GrimoireEntry]) =
  ## Adds the entries to the grimoire.
  for entry in entries:
    self.add entry

func init*(T: type Grimoire, entries: openArray[GrimoireEntry] = []): T =
  var grimoire = T(
    simulator: Simulator.init,
    entries: @[],
    matchedEntryIds: set[int16]({}),
    allIds: set[int16]({}),
    ruleToIds: Rule.initArrayWith set[int16]({}),
    moveCountToIds: @[],
    kindToIds: GoalKind.initArrayWith set[int16]({}),
    noKindIds: set[int16]({}),
    hasClearColorToIds: 2.initArrayWith set[int16]({}),
    titleSuffixArray: SuffixArray.init newSeq[string](),
    titleIndexToIds: @[],
    creatorSuffixArray: SuffixArray.init newSeq[string](),
    creatorIndexToIds: @[],
    sourceSuffixArray: SuffixArray.init newSeq[string](),
    sourceIndexToIds: @[],
    idToIndex: @[],
    sortedSources: @[],
    isReady: false,
  )

  grimoire.add entries

  grimoire

func init*(
    T: type GrimoireMatcher,
    ruleOpt = Opt[Rule].err,
    moveCountOpt = Opt[int].err,
    kindOptOpt = Opt[Opt[GoalKind]].err,
    hasClearColorOpt = Opt[bool].err,
    titleOpt = Opt[string].err,
    creatorOpt = Opt[string].err,
    sourceOpt = Opt[string].err,
): T =
  T(
    ruleOpt: ruleOpt,
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

func getEntry*(self: Grimoire, id: int16): Pon2Result[GrimoireEntry] =
  ## Returns the entry with the specified ID.
  if id in 0 ..< self.idToIndex.len:
    let index = self.idToIndex[id]
    if index in 0 ..< self.entries.len:
      ok self.entries[index]
    else:
      err "ID {id} is not registered".fmt
  else:
    err "ID {id} is not registered".fmt

func isReady*(self: Grimoire): bool =
  ## Returns `true` if the grimoire is ready.
  self.isReady

func `isReady=`*(self: var Grimoire, isReady: bool) =
  ## Performs the preprocessing of the grimoire and sets `isReady`.
  # prepare IDs, sorted sources
  var
    titleToIds = initTable[string, set[int16]]()
    creatorToIds = initTable[string, set[int16]]()
    sourceToIds = initTable[string, set[int16]]()
    sourcesSet = initHashSet[string]()
    maxId = int16.low
  for entry in self.entries:
    if entry.title.len > 0:
      titleToIds.mgetOrPut(entry.title.normalized, {}).incl entry.id
    for creator in entry.creators:
      creatorToIds.mgetOrPut(creator.normalized, {}).incl entry.id
    if entry.source.len > 0:
      sourceToIds.mgetOrPut(entry.source.normalized, {}).incl entry.id
      sourcesSet.incl entry.source

    self.allIds.incl entry.id
    maxId = max(entry.id, maxId)

  # sort entries by their IDs
  self.entries.sort (x, y: GrimoireEntry) => cmp(x.id, y.id)

  # ID -> index
  self.idToIndex.assign (-1).repeat maxId + 1
  for entryIndex, entry in self.entries:
    self.idToIndex[entry.id].assign entryIndex

  # match all
  self.matchedEntryIds.assign self.allIds

  # title
  let titleCount = titleToIds.len
  var titles = newSeqOfCap[string](titleCount)
  self.titleIndexToIds.assign newSeqOfCap[set[int16]](titleCount)
  for (title, ids) in titleToIds.pairs:
    titles.add title
    self.titleIndexToIds.add ids
  self.titleSuffixArray.assign SuffixArray.init titles

  # creator
  let creatorCount = creatorToIds.len
  var creators = newSeqOfCap[string](creatorCount)
  self.creatorIndexToIds.assign newSeqOfCap[set[int16]](creatorCount)
  for (creator, ids) in creatorToIds.pairs:
    creators.add creator
    self.creatorIndexToIds.add ids
  self.creatorSuffixArray.assign SuffixArray.init creators

  # source
  let sourceCount = sourceToIds.len
  var sources = newSeqOfCap[string](sourceCount)
  self.sourceIndexToIds.assign newSeqOfCap[set[int16]](sourceCount)
  for (source, ids) in sourceToIds.pairs:
    sources.add source
    self.sourceIndexToIds.add ids
  self.sourceSuffixArray.assign SuffixArray.init sources

  # sort source
  self.sortedSources.assign sourcesSet.toSeq.sorted

  self.isReady.assign isReady

func len*(self: Grimoire): int =
  ## Returns the number of the entries.
  self.entries.len

func matchedEntryIds*(self: Grimoire): set[int16] =
  ## Returns the sorted IDs of the matched entries.
  self.matchedEntryIds

func moveCountMax*(self: Grimoire): int =
  ## Returns the max move count of the Nazo Puyo in the grimoire.
  self.moveCountToIds.len - 1

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

  self.matchedEntryIds.assign self.allIds

  # rule
  if matcher.ruleOpt.isOk:
    let rule = matcher.ruleOpt.unsafeValue
    self.matchedEntryIds *= self.ruleToIds[rule]

  # move count
  if matcher.moveCountOpt.isOk:
    let moveCount = matcher.moveCountOpt.unsafeValue
    if moveCount in 0 ..< self.moveCountToIds.len:
      self.matchedEntryIds *= self.moveCountToIds[moveCount]
    else:
      self.matchedEntryIds.assign {}
      return

  # kind
  if matcher.kindOptOpt.isOk:
    let kindOpt = matcher.kindOptOpt.unsafeValue
    if kindOpt.isOk:
      self.matchedEntryIds *= self.kindToIds[kindOpt.unsafeValue]
    else:
      self.matchedEntryIds *= self.noKindIds

  # clear color
  if matcher.hasClearColorOpt.isOk:
    let hasClearColor = matcher.hasClearColorOpt.unsafeValue
    self.matchedEntryIds *= self.hasClearColorToIds[hasClearColor.int]

  # title
  if matcher.titleOpt.isOk:
    let title = matcher.titleOpt.unsafeValue

    var ids = set[int16]({})
    for titleIndex in self.titleSuffixArray.findAll title:
      ids += self.titleIndexToIds[titleIndex]
    self.matchedEntryIds *= ids

  # creator
  if matcher.creatorOpt.isOk:
    let creator = matcher.creatorOpt.unsafeValue

    var ids = set[int16]({})
    for creatorIndex in self.creatorSuffixArray.findAll creator:
      ids += self.creatorIndexToIds[creatorIndex]
    self.matchedEntryIds *= ids

  # source
  if matcher.sourceOpt.isOk:
    let source = matcher.sourceOpt.unsafeValue

    var ids = set[int16]({})
    for sourceIndex in self.sourceSuffixArray.findAll source:
      ids += self.sourceIndexToIds[sourceIndex]
    self.matchedEntryIds *= ids
