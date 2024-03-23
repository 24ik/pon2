## This module implements marathon mode.
##
# NOTE (Implementation approach): To prevent slow page loading and rendering,
# data is basically handled as `string` and conversion to `Pair` is performed
# when necessary.

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[algorithm, critbits, math, os, sequtils, strutils, sugar, random]
import ./[key, simulator]
import ../core/[cell, field, puyopuyo]
import ../private/[misc]
import ../private/app/marathon/[common]

type Marathon* = object ## Marathon manager.
  simulator*: ref Simulator

  matchPairsStrsSeq*: seq[string]
  matchResultPageCount*: Natural
  matchResultPageIndex*: Natural

  allPairsStrsSeq: seq[string]
  allPairsStrsTree: CritBitTree[void]

  focusSimulator: bool

  rng: Rand

const RawPairsTxt = staticRead currentSourcePath().parentDir.parentDir.parentDir.parentDir /
  "assets" / "pairs" / "swap.txt"

using
  self: Marathon
  mSelf: var Marathon

# ------------------------------------------------
# Constructor
# ------------------------------------------------

proc initMarathon*(): Marathon {.inline.} =
  ## Returns a new marathon manager.
  result.simulator = new Simulator
  result.simulator[] = initPuyoPuyo[TsuField]().initSimulator(Play, true)

  result.matchPairsStrsSeq = @[]
  result.matchResultPageCount = 0
  result.matchResultPageIndex = 0

  result.allPairsStrsSeq = RawPairsTxt.splitLines
  result.allPairsStrsTree = result.allPairsStrsSeq.toCritBitTree
  assert result.allPairsStrsSeq.len == AllPairsCount

  result.focusSimulator = false

  result.rng = initRand()

# ------------------------------------------------
# Property
# ------------------------------------------------

func focusSimulator*(self): bool {.inline.} =
  ## Returns `true` if the simulator is focused.
  self.focusSimulator

# ------------------------------------------------
# Edit - Other
# ------------------------------------------------

func toggleFocus*(mSelf) {.inline.} = ## Toggles focusing to the simulator or not.
  mSelf.focusSimulator.toggle

# ------------------------------------------------
# Table Page
# ------------------------------------------------

proc nextResultPage*(mSelf) {.inline.} =
  ## Shows the next result page.
  if mSelf.matchResultPageCount == 0:
    return

  if mSelf.matchResultPageIndex == mSelf.matchResultPageCount.pred:
    mSelf.matchResultPageIndex = 0
  else:
    mSelf.matchResultPageIndex.inc

proc prevResultPage*(mSelf) {.inline.} =
  ## Shows the previous result page.
  if mSelf.matchResultPageCount == 0:
    return

  if mSelf.matchResultPageIndex == 0:
    mSelf.matchResultPageIndex = mSelf.matchResultPageCount.pred
  else:
    mSelf.matchResultPageIndex.dec

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

{.push warning[Uninit]: off.}
func match*(mSelf; prefix: string) {.inline.} =
  if prefix == "":
    mSelf.matchPairsStrsSeq = @[]
  else:
    var keys = prefix.toSet2
    if keys in NeedReplaceKeysSeq:
      if prefix.len mod 2 == 1:
        return

      let prefix2 = prefix.toUpperAscii # HACK: prevent to confuse 'b' with Blue

      mSelf.matchPairsStrsSeq = newSeqOfCap[string](45000)
      for replaceData in ReplaceDataSeq[keys.card.pred]:
        for prefix3 in prefix2.swappedPrefixes:
          {.push warning[ProveInit]: off.}
          mSelf.matchPairsStrsSeq &=
            mSelf.allPairsStrsTree.itemsWithPrefix(prefix3.multiReplace replaceData).toSeq
          {.pop.}
    else:
      {.push warning[ProveInit]: off.}
      mSelf.matchPairsStrsSeq = mSelf.allPairsStrsTree.itemsWithPrefix(prefix).toSeq
      {.pop.}

  mSelf.matchResultPageCount =
    ceil(mSelf.matchPairsStrsSeq.len / MatchResultPairsCountPerPage).Natural
  mSelf.matchResultPageIndex = 0

  if mSelf.matchPairsStrsSeq.len > 0:
    mSelf.focusSimulator = false
{.pop.}

# ------------------------------------------------
# Play
# ------------------------------------------------

proc play(mSelf; pairsStr: string) {.inline.} =
  ## Plays a marathon mode with the given pairs.
  mSelf.simulator[].reset true
  mSelf.simulator[].pairsPositions = pairsStr.toPairsPositions

  mSelf.focusSimulator = true

proc play*(mSelf; pairsIdx: Natural) {.inline.} =
  ## Plays a marathon mode with the given pairs.
  mSelf.play mSelf.matchPairsStrsSeq[pairsIdx]

proc play*(mSelf; onlyMatched = true) {.inline.} =
  ## Plays a marathon mode with the random mathced pairs.
  ## If `onlyMatched` is true, the pairs are chosen from the matched result;
  ## otherwise, chosen from all pairs.
  if not onlyMatched:
    mSelf.play mSelf.rng.sample mSelf.allPairsStrsSeq
    return

  if mSelf.matchPairsStrsSeq.len == 0:
    return

  mSelf.play mSelf.rng.sample mSelf.matchPairsStrsSeq

# ------------------------------------------------
# Keyboard Operation
# ------------------------------------------------

proc operate*(mSelf; event: KeyEvent): bool {.inline.} =
  ## Does operation specified by the keyboard input.
  ## Returns `true` if any action is executed.
  if event == initKeyEvent("KeyQ", shift = true):
    mSelf.toggleFocus
    return true

  if mSelf.focusSimulator:
    return mSelf.simulator[].operate event

  result = false

# ------------------------------------------------
# Backend-specific Implementation
# ------------------------------------------------

when defined(js):
  import std/[dom]
  import karax/[karax, karaxdsl, vdom]
  import
    ../private/app/marathon/web/
      [controller, pagination, searchbar, searchresult, simulator]

  # ------------------------------------------------
  # JS - Keyboard Handler
  # ------------------------------------------------

  proc runKeyboardEventHandler*(mSelf; event: KeyEvent) {.inline.} =
    ## Runs the keyboard event handler.
    let needRedraw = mSelf.operate event
    if needRedraw and not kxi.surpressRedraws:
      kxi.redraw

  proc runKeyboardEventHandler*(mSelf; event: dom.Event) {.inline.} =
    ## Runs the Keybaord event handler.
    # assert event of KeyboardEvent # HACK: somehow this assertion fails
    mSelf.runKeyboardEventHandler cast[KeyboardEvent](event).toKeyEvent

  proc initKeyboardEventHandler*(mSelf): (event: dom.Event) -> void {.inline.} =
    ## Returns the keyboard event handler.
    (event: dom.Event) => mSelf.runKeyboardEventHandler event

  # ------------------------------------------------
  # JS - Node
  # ------------------------------------------------

  proc initMarathonNode(mSelf; id: string): VNode {.inline.} =
    ## Returns the node of marathon manager.
    ## `id` is shared with other node-creating procedures and need to be unique.
    buildHtml(tdiv(class = "columns is-mobile")):
      tdiv(class = "column is-narrow"):
        tdiv(class = "block"):
          mSelf.initMarathonPlayControllerNode
        tdiv(class = "block"):
          mSelf.initMarathonSimulatorNode id
      tdiv(class = "column is-narrow"):
        tdiv(class = "block"):
          mSelf.initMarathonSearchBarNode id
        tdiv(class = "block"):
          mSelf.initMarathonFocusControllerNode
        tdiv(class = "block"):
          mSelf.initMarathonPaginationNode
        if mSelf.matchPairsStrsSeq.len > 0:
          tdiv(class = "block"):
            mSelf.initMarathonSearchResultNode

  proc initMarathonNode*(
      mSelf; setKeyHandler = true, wrapSection = true, id = ""
  ): VNode {.inline.} =
    ## Returns the node of marathon manager.
    ## `id` is shared with other node-creating procedures and need to be unique.
    if setKeyHandler:
      document.onkeydown = mSelf.initKeyboardEventHandler

    if wrapSection:
      result = buildHtml(section(class = "section")):
        mSelf.initMarathonNode id
    else:
      result = mSelf.initMarathonNode id
