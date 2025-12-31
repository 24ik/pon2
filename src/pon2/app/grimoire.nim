## This module implements the Nazo Puyo Grimoire.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[random, sugar]
import ./[simulator]
import ../[core]
import ../private/[arrayutils, assign, setutils, tables]

type
  NazoPuyoEntry* = object ## Entry of the Nazo Puyo Grimoire.
    query*: string
    author*: string
    title*: string
    source*: string

  NazoPuyoGrimoire* = object ## Nazo Puyo Grimoire.
    simulator*: Simulator

    allEntries: seq[NazoPuyoEntry]
    matchedEntryIndices: seq[int]

    moveCountToIndices: seq[set[int16]]
    kindToIndices: array[GoalKind, set[int16]]
    noneKindIndices: set[int16]
    clearColorToIndices: array[GoalColor, set[int16]]
    noneClearColorIndices: set[int16]
    authorToIndices: Table[string, set[int16]]
    titleToIndices: Table[string, set[int16]]
    sourceToIndices: Table[string, set[int16]]

    isReady*: bool
    rng: Rand

  NazoPuyoMatcher* = object ## Matcher of the Nazo Puyo Grimoire.
    moveCountOpt: Opt[int]
    kindOptOpt: Opt[Opt[GoalKind]]
    clearColorOptOpt: Opt[Opt[GoalColor]]
    authorOpt: Opt[string]
    titleOpt: Opt[string]
    sourceOpt: Opt[string]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(
    T: type NazoPuyoEntry, query: string, author = "", title = "", source = ""
): T =
  T(query: query, author: author, title: title, source: source)

func add(self: var NazoPuyoGrimoire, entry: NazoPuyoEntry) =
  ## Adds the entry to the grimoire.
  if self.isReady:
    return

  # load Nazo Puyo
  let nazoPuyoResult = entry.query.parseNazoPuyo Pon2
  if nazoPuyoResult.isErr:
    return
  let nazoPuyo = nazoPuyoResult.unsafeValue

  let entryIndex = self.allEntries.len.int16
  self.allEntries.add entry

  # moveCount
  let moveCount = nazoPuyo.puyoPuyo.steps.len
  if moveCount + 1 > self.moveCountToIndices.len:
    self.moveCountToIndices.setLen moveCount + 1
  self.moveCountToIndices[moveCount].incl entryIndex

  # kind
  if nazoPuyo.goal.mainOpt.isOk:
    self.kindToIndices[nazoPuyo.goal.mainOpt.unsafeValue.kind].incl entryIndex
  else:
    self.noneKindIndices.incl entryIndex

  # clear color
  if nazoPuyo.goal.clearColorOpt.isOk:
    self.clearColorToIndices[nazoPuyo.goal.clearColorOpt.unsafeValue].incl entryIndex
  else:
    self.noneClearColorIndices.incl entryIndex

  # author, title, source
  self.authorToIndices.mgetOrPut(entry.author, set[int16]({})).incl entryIndex
  self.titleToIndices.mgetOrPut(entry.title, set[int16]({})).incl entryIndex
  self.sourceToIndices.mgetOrPut(entry.source, set[int16]({})).incl entryIndex

func add*(self: var NazoPuyoGrimoire, entries: openArray[NazoPuyoEntry]) =
  ## Adds the entries to the grimoire.
  for entry in entries:
    self.add entry

func init*(
    T: type NazoPuyoGrimoire, rng: Rand, entries: openArray[NazoPuyoEntry] = []
): T =
  var grimoire = T(
    simulator: Simulator.init,
    allEntries: @[],
    matchedEntryIndices: @[],
    moveCountToIndices: @[],
    kindToIndices: GoalKind.initArrayWith set[int16]({}),
    noneKindIndices: set[int16]({}),
    clearColorToIndices: GoalColor.initArrayWith set[int16]({}),
    noneClearColorIndices: set[int16]({}),
    authorToIndices: initTable[string, set[int16]](),
    titleToIndices: initTable[string, set[int16]](),
    sourceToIndices: initTable[string, set[int16]](),
    isReady: false,
    rng: rng,
  )

  grimoire.add entries

  grimoire

func init*(
    T: type NazoPuyoMatcher,
    moveCountOpt = Opt[int].err,
    kindOptOpt = Opt[Opt[GoalKind]].err,
    clearColorOptOpt = Opt[Opt[GoalColor]].err,
    authorOpt = Opt[string].err,
    titleOpt = Opt[string].err,
    sourceOpt = Opt[string].err,
): T =
  T(
    moveCountOpt: moveCountOpt,
    kindOptOpt: kindOptOpt,
    clearColorOptOpt: clearColorOptOpt,
    authorOpt: authorOpt,
    titleOpt: titleOpt,
    sourceOpt: sourceOpt,
  )

# ------------------------------------------------
# Property
# ------------------------------------------------

func `[]`*(self: NazoPuyoGrimoire, index: int): NazoPuyo =
  self.allEntries[index].query.parseNazoPuyo(Pon2).unsafeValue

func len*(self: NazoPuyoGrimoire): int =
  ## Returns the number of the entries.
  if self.isReady: self.allEntries.len else: 0

func matchedEntryIndices*(self: NazoPuyoGrimoire): seq[int] =
  ## Returns the number of the matched entry.
  if self.isReady:
    self.matchedEntryIndices
  else:
    @[]

# ------------------------------------------------
# Match
# ------------------------------------------------

func match*(self: var NazoPuyoGrimoire, matcher: NazoPuyoMatcher) =
  ## Searches by the matcher.
  if not self.isReady:
    return

  var indices = (0'i16 ..< self.allEntries.len.int16).toSet

  if matcher.moveCountOpt.isOk:
    let moveCount = matcher.moveCountOpt.unsafeValue
    if moveCount in 0 ..< self.moveCountToIndices.len:
      indices *= self.moveCountToIndices[moveCount]
    else:
      indices.assign {}

  if matcher.kindOptOpt.isOk:
    let kindOpt = matcher.kindOptOpt.unsafeValue
    if kindOpt.isOk:
      indices *= self.kindToIndices[kindOpt.unsafeValue]
    else:
      indices *= self.noneKindIndices

  if matcher.clearColorOptOpt.isOk:
    let clearColorOpt = matcher.clearColorOptOpt.unsafeValue
    if clearColorOpt.isOk:
      indices *= self.clearColorToIndices[clearColorOpt.unsafeValue]
    else:
      indices *= self.noneClearColorIndices

  if matcher.authorOpt.isOk:
    let author = matcher.authorOpt.unsafeValue
    indices *= self.authorToIndices.getOrDefault(author, {})

  if matcher.titleOpt.isOk:
    let title = matcher.titleOpt.unsafeValue
    indices *= self.titleToIndices.getOrDefault(title, {})

  if matcher.sourceOpt.isOk:
    let source = matcher.sourceOpt.unsafeValue
    indices *= self.sourceToIndices.getOrDefault(source, {})

  let indicesSeq = collect:
    for index in indices:
      index.int
  self.matchedEntryIndices.assign indicesSeq
