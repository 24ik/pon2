## This module implements marathon mode.
##

# NOTE: `std/critbits` is incompatible with `strictCaseObjects` in Nim-2.2.0
{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[algorithm, critbits, math, options, os, sequtils, strutils, sugar, random]
import ./[key, nazopuyo, simulator]
import ../core/[cell, field, puyopuyo]
import ../private/[misc]
import ../private/app/[misc]
import ../private/app/marathon/[common]

when defined(js):
  import std/[asyncjs, jsconsole, jsfetch]

type
  MarathonMatchResult* = object ## Matching result.
    strings*: seq[string]
    pageCount*: Natural
    pageIndex*: Natural

  MarathonObj = object ## Marathon manager.
    simulator: ref Simulator

    allPairsStrs: Option[tuple[`seq`: seq[string], tree: CritBitTree[void]]]
    matchResult: MarathonMatchResult

    focusSimulator: bool

    rng: Rand

  Marathon* = ref MarathonObj ## Marathon manager.

# ------------------------------------------------
# Constructor
# ------------------------------------------------

proc newMarathon*(rng = initRand()): Marathon {.inline.} =
  ## Returns a new marathon manager without pairs' data loaded.
  let simulator = new Simulator
  simulator[] = initPuyoPuyo[TsuField]().initSimulator Play

  result = Marathon(
    simulator: simulator,
    allPairsStrs: none tuple[`seq`: seq[string], tree: CritBitTree[void]],
    matchResult: MarathonMatchResult(strings: @[], pageCount: 0, pageIndex: 0),
    focusSimulator: false,
    rng: rng,
  )

proc loadData(self: Marathon, pairsStr: string) {.inline.} =
  ## Loads pairs' data.
  let allPairsStrsSeq = pairsStr.splitLines
  assert allPairsStrsSeq.len == AllPairsCount

  self.allPairsStrs = some (`seq`: allPairsStrsSeq, tree: allPairsStrsSeq.toCritBitTree)

when defined(js):
  {.push warning[Uninit]: off.}
  proc asyncLoadDataImpl(self: Marathon, completeHandler: () -> void) {.async.} =
    ## Loads pairs' data asynchronously.
    ## This procedure should be called with `discard`.
    {.push warning[ProveInit]: off.}
    await (WebAssetsDir / "pairs" / "swap.txt").cstring.fetch
    .then((r: Response) => r.text)
    .then((s: cstring) => (self.loadData $s; completeHandler()))
    .catch((e: Error) => console.error e)
    {.pop.}

  {.pop.}

  proc asyncLoadData*(
      self: Marathon, completeHandler: () -> void = () => (discard)
  ) {.inline.} =
    ## Loads pairs' data asynchronously.
    discard self.asyncLoadDataImpl completeHandler

else:
  const SwapPairsTxt = staticRead NativeAssetsDir / "pairs" / "swap.txt"

  proc loadData*(self: Marathon) {.inline.} =
    ## Loads pairs' data.
    self.loadData SwapPairsTxt

# ------------------------------------------------
# Property
# ------------------------------------------------

func simulator*(self: Marathon): ref Simulator {.inline.} =
  ## Returns the simulator.
  self.simulator

func matchResult*(self: Marathon): MarathonMatchResult {.inline.} =
  ## Returns the matching result.
  self.matchResult

func focusSimulator*(self: Marathon): bool {.inline.} =
  ## Returns `true` if the simulator is focused.
  self.focusSimulator

func isReady*(self: Marathon): bool {.inline.} =
  ## Returns `true` if the pairs' data is loaded.
  self.allPairsStrs.isSome

# ------------------------------------------------
# Edit - Other
# ------------------------------------------------

proc toggleFocus*(self: Marathon) {.inline.} =
  ## Toggles focusing to the simulator or not.
  self.focusSimulator.toggle

# ------------------------------------------------
# Table Page
# ------------------------------------------------

proc nextResultPage*(self: Marathon) {.inline.} =
  ## Shows the next result page.
  if self.matchResult.pageCount == 0:
    return

  if self.matchResult.pageIndex == self.matchResult.pageCount.pred:
    self.matchResult.pageIndex = 0
  else:
    self.matchResult.pageIndex.inc

proc prevResultPage*(self: Marathon) {.inline.} =
  ## Shows the previous result page.
  if self.matchResult.pageCount == 0:
    return

  if self.matchResult.pageIndex == 0:
    self.matchResult.pageIndex = self.matchResult.pageCount.pred
  else:
    self.matchResult.pageIndex.dec

# ------------------------------------------------
# Match
# ------------------------------------------------

func swappedPrefixes(prefix: string): seq[string] {.inline.} =
  ## Returns all prefixes with all pairs swapped.
  ## `prefix` need to be capital.
  assert prefix.len mod 2 == 0

  # If a non-double pair (AB) exists and cells in the pair (A and B) do not
  # appear in the others pairs, A and B are symmetric; no need to swap in this
  # function.
  # This process is applied to only one of all AB (fixing the concrete colors of
  # A and B).
  var
    pairIdx = [0, 0, 0, 0, 0, 0] # AB, AC, AD, BC, BD, CD
    pairCounts = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0] # AB, ..., CD, AA, BB, CC, DD
  for i in countup(0, prefix.len.pred, 2):
    case prefix[i .. i.succ]
    of "AA":
      pairCounts[6].inc
    of "BB":
      pairCounts[7].inc
    of "CC":
      pairCounts[8].inc
    of "DD":
      pairCounts[9].inc
    of "AB", "BA":
      pairCounts[0].inc
      pairIdx[0] = i
    of "AC", "CA":
      pairCounts[1].inc
      pairIdx[1] = i
    of "AD", "DA":
      pairCounts[2].inc
      pairIdx[2] = i
    of "BC", "CB":
      pairCounts[3].inc
      pairIdx[3] = i
    of "BD", "DB":
      pairCounts[4].inc
      pairIdx[4] = i
    of "CD", "DC":
      pairCounts[5].inc
      pairIdx[5] = i

  let
    notDoublePairCount = pairCounts[0 ..< 6].sum2
    fixIdx =
      if pairCounts[0] > 0 and notDoublePairCount == pairCounts[0] and
          pairCounts[6] + pairCounts[7] == 0:
        pairIdx[0]
      elif pairCounts[1] > 0 and notDoublePairCount == pairCounts[1] and
        pairCounts[6] + pairCounts[8] == 0:
        pairIdx[1]
      elif pairCounts[2] > 0 and notDoublePairCount == pairCounts[2] and
        pairCounts[6] + pairCounts[9] == 0:
        pairIdx[2]
      elif pairCounts[3] > 0 and notDoublePairCount == pairCounts[3] and
        pairCounts[7] + pairCounts[8] == 0:
        pairIdx[3]
      elif pairCounts[4] > 0 and notDoublePairCount == pairCounts[4] and
        pairCounts[7] + pairCounts[9] == 0:
        pairIdx[4]
      elif pairCounts[5] > 0 and notDoublePairCount == pairCounts[5] and
        pairCounts[8] + pairCounts[9] == 0:
        pairIdx[5]
      else:
        -1

    pairsSeq = collect:
      for i in countup(0, prefix.len.pred, 2):
        let
          c1 = prefix[i]
          c2 = prefix[i.succ]

        if c1 == c2 or i == fixIdx:
          @[c1 & c2]
        else:
          @[c1 & c2, c2 & c1]

  result = pairsSeq.product2.mapIt it.join

func initReplaceData(keys: string): seq[seq[(string, string)]] {.inline.} =
  ## Returns arguments for prefix replacing.
  case keys.len
  of 1:
    result = collect:
      for p0 in ColorPuyo.low .. ColorPuyo.high:
        @[($keys[0], $p0)]
  of 2:
    result = collect:
      for p0 in ColorPuyo.low .. ColorPuyo.high:
        for p1 in ColorPuyo.low .. ColorPuyo.high:
          if p0 != p1:
            @[($keys[0], $p0), ($keys[1], $p1)]
  of 3:
    result = collect:
      for p0 in ColorPuyo.low .. ColorPuyo.high:
        for p1 in ColorPuyo.low .. ColorPuyo.high:
          for p2 in ColorPuyo.low .. ColorPuyo.high:
            if {p0, p1, p2}.card == 3:
              @[($keys[0], $p0), ($keys[1], $p1), ($keys[2], $p2)]
  of 4:
    result = collect:
      for p0 in ColorPuyo.low .. ColorPuyo.high:
        for p1 in ColorPuyo.low .. ColorPuyo.high:
          for p2 in ColorPuyo.low .. ColorPuyo.high:
            for p3 in ColorPuyo.low .. ColorPuyo.high:
              if {p0, p1, p2, p3}.card == 4:
                @[($keys[0], $p0), ($keys[1], $p1), ($keys[2], $p2), ($keys[3], $p3)]
  else:
    result = @[] # HACK: dummy to suppress warning
    assert false

const
  ReplaceDataSeq = [
    "A".initReplaceData, "AB".initReplaceData, "ABC".initReplaceData,
    "ABCD".initReplaceData,
  ]
  NeedReplaceKeysSeq = ["a".toSet2, "ab".toSet2, "abc".toSet2, "abcd".toSet2]

proc match*(self: Marathon, prefix: string) {.inline.} =
  if prefix == "":
    self.matchResult.strings = @[]
  else:
    var keys = prefix.toSet2
    if keys in NeedReplaceKeysSeq:
      if prefix.len mod 2 == 1:
        return

      let prefix2 = prefix.toUpperAscii # HACK: prevent to confuse 'b' with Blue

      self.matchResult.strings = newSeqOfCap(45000)
      for replaceData in ReplaceDataSeq[keys.card.pred]:
        for prefix3 in prefix2.swappedPrefixes:
          {.push warning[ProveInit]: off.}
          self.matchResult.strings &=
            self.allPairsStrs.get.tree.itemsWithPrefix(prefix3.multiReplace replaceData).toSeq
          {.pop.}
    else:
      self.matchResult.strings =
        self.allPairsStrs.get.tree.itemsWithPrefix(prefix).toSeq

  self.matchResult.pageCount =
    ceil(self.matchResult.strings.len / MatchResultPairsCountPerPage).Natural
  self.matchResult.pageIndex = 0

  if self.matchResult.strings.len > 0:
    self.focusSimulator = false

# ------------------------------------------------
# Play
# ------------------------------------------------

proc play(self: Marathon, pairsStr: string) {.inline.} =
  ## Plays a marathon mode with the given pairs.
  self.simulator[].reset
  self.simulator[].nazoPuyoWrap.get:
    wrappedNazoPuyo.puyoPuyo.pairsPositions = pairsStr.toPairsPositions

  self.focusSimulator = true

proc play*(self: Marathon, pairsIdx: Natural) {.inline.} =
  ## Plays a marathon mode with the given pairs.
  self.play self.matchResult.strings[pairsIdx]

proc play*(self: Marathon, onlyMatched = true) {.inline.} =
  ## Plays a marathon mode with the random mathced pairs.
  ## If `onlyMatched` is true, the pairs are chosen from the matched result;
  ## otherwise, chosen from all pairs.
  if not onlyMatched:
    {.push warning[ProveInit]: off.}
    self.play self.rng.sample self.allPairsStrs.get.seq
    {.pop.}
    return

  if self.matchResult.strings.len == 0:
    return

  self.play self.rng.sample self.matchResult.strings

# ------------------------------------------------
# Keyboard Operation
# ------------------------------------------------

proc operate*(self: Marathon, event: KeyEvent): bool {.inline.} =
  ## Does operation specified by the keyboard input.
  ## Returns `true` if any action is executed.
  if event == initKeyEvent("Tab", shift = true):
    self.toggleFocus
    return true

  if self.focusSimulator:
    return self.simulator[].operate event

  result = false

# ------------------------------------------------
# Backend-specific Implementation
# ------------------------------------------------

when defined(js):
  import std/[strformat]
  import karax/[karax, karaxdsl, kdom, vdom]
  import
    ../private/app/marathon/web/
      [controller, pagination, searchbar, searchresult, simulator as simulatorModule]

  # ------------------------------------------------
  # JS - Keyboard Handler
  # ------------------------------------------------

  proc runKeyboardEventHandler*(
      self: Marathon, event: KeyEvent
  ): bool {.inline, discardable.} =
    ## Runs the keyboard event handler.
    ## Returns `true` if any action is executed.
    result = self.operate event
    if result and not kxi.surpressRedraws:
      kxi.redraw

  proc runKeyboardEventHandler*(
      self: Marathon, event: Event
  ): bool {.inline, discardable.} =
    ## Runs the keyboard event handler.
    # assert event of KeyboardEvent # HACK: somehow this fails

    result = self.runKeyboardEventHandler cast[KeyboardEvent](event).toKeyEvent
    if result:
      event.preventDefault

  func newKeyboardEventHandler*(self: Marathon): (event: Event) -> void {.inline.} =
    ## Returns the keyboard event handler.
    (event: Event) => (discard self.runKeyboardEventHandler event)

  # ------------------------------------------------
  # JS - Node
  # ------------------------------------------------

  const
    SimulatorIdPrefix = "pon2-marathon-simulator-"
    SearchBarIdPrefix = "pon2-marathon-searchbar-"

  proc newMarathonNode(self: Marathon, id: string): VNode {.inline.} =
    ## Returns the node of marathon manager.
    buildHtml(tdiv(class = "columns is-mobile")):
      tdiv(class = "column is-narrow"):
        tdiv(class = "block"):
          self.newMarathonPlayControllerNode
        tdiv(class = "block"):
          self.newMarathonSimulatorNode &"{SimulatorIdPrefix}{id}"
      tdiv(class = "column is-narrow"):
        tdiv(class = "block"):
          self.newMarathonSearchBarNode &"{SearchBarIdPrefix}{id}"
        if not isMobile():
          tdiv(class = "block"):
            self.newMarathonFocusControllerNode
        tdiv(class = "block"):
          self.newMarathonPaginationNode
        if self.matchResult.strings.len > 0:
          tdiv(class = "block"):
            self.newMarathonSearchResultNode

  proc newMarathonNode*(
      self: Marathon, setKeyHandler = true, wrapSection = true, id = ""
  ): VNode {.inline.} =
    ## Returns the node of marathon manager.
    ## `id` is shared with other node-creating procedures and need to be unique.
    if setKeyHandler:
      document.onkeydown = self.newKeyboardEventHandler

    let node = self.newMarathonNode id

    if wrapSection:
      result = buildHtml(section(class = "section")):
        node
    else:
      result = node
