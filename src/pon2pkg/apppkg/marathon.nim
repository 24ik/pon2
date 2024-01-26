## This module implements marathon mode.
##
# NOTE (Implementation approach): To prevent slow page loading and rendering,
# data is basically handled as `string` and conversion to `Pairs` is performed
# when necessary.

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[critbits, math, os, sequtils, strutils, random]
import ./[misc, simulator]
import ../corepkg/[environment, misc, pair]
import ../private/[misc]

when defined(js):
  import ../nazopuyopkg/[nazopuyo]

type Marathon* = object
  ## Marathon manager.
  simulator*: ref Simulator

  matchPairsStrsSeq*: seq[string]
  matchResultPageCount*: Natural
  matchResultPageIdx*: Natural

  allPairsStrsSeq: seq[string]
  allPairsStrsTree: CritBitTree[void]

  focusSimulator*: bool

  rng: Rand

const
  RawPairsTxt =
    staticRead currentSourcePath().parentDir.parentDir.parentDir.parentDir /
      "assets/pairs/haipuyo.txt"
  MatchResultPairsCountPerPage* = 10

using
  self: Marathon
  mSelf: var Marathon

# ------------------------------------------------
# Constructor
# ------------------------------------------------

proc initMarathon*: Marathon {.inline.} =
  ## Returns a new marathon manager.
  result.simulator = new Simulator
  result.simulator[] =
    0.initTsuEnvironment(setPairs = false).initSimulator(Play, true)

  result.matchPairsStrsSeq = @[]
  result.matchResultPageCount = 0
  result.matchResultPageIdx = 0

  result.allPairsStrsSeq = RawPairsTxt.splitLines
  result.allPairsStrsTree = result.allPairsStrsSeq.toCritBitTree

  result.focusSimulator = false

  result.rng = initRand()

# ------------------------------------------------
# Pairs
# ------------------------------------------------

func toPairs*(str: string): Pairs {.inline.} =
  ## Converts the flattened string to the pairs.
  result = initDeque[Pair](str.len div 2)
  for i in countup(0, str.len.pred, 2):
    result.addLast str[i..i.succ].parsePair

# ------------------------------------------------
# Edit - Other
# ------------------------------------------------

func toggleFocus*(mSelf) {.inline.} = mSelf.focusSimulator.toggle
  ## Toggles focusing to the simulator or not.

# ------------------------------------------------
# Table Page
# ------------------------------------------------

proc nextResultPage*(mSelf) {.inline.} =
  ## Shows the next result page.
  if mSelf.matchResultPageCount == 0:
    return

  if mSelf.matchResultPageIdx == mSelf.matchResultPageCount.pred:
    mSelf.matchResultPageIdx = 0
  else:
    mSelf.matchResultPageIdx.inc

proc prevResultPage*(mSelf) {.inline.} =
  ## Shows the previous result page.
  if mSelf.matchResultPageCount == 0:
    return

  if mSelf.matchResultPageIdx == 0:
    mSelf.matchResultPageIdx = mSelf.matchResultPageCount.pred
  else:
    mSelf.matchResultPageIdx.dec

# ------------------------------------------------
# Match
# ------------------------------------------------

{.push warning[Uninit]: off.}
func match*(mSelf; prefix: string) {.inline.} =
  ## Updates `mSelf.matchPairsStrsSeq`.
  {.push warning[ProveInit]: off.}
  mSelf.matchPairsStrsSeq =
    if prefix == "": newSeq[string](0)
    else: toSeq mSelf.allPairsStrsTree.itemsWithPrefix prefix
  {.pop.}

  mSelf.matchResultPageCount =
    ceil(mSelf.matchPairsStrsSeq.len / MatchResultPairsCountPerPage).Natural
  mSelf.matchResultPageIdx = 0
{.pop.}

# ------------------------------------------------
# Play
# ------------------------------------------------

proc play(mSelf; pairsStr: string) {.inline.} =
  ## Plays a marathon mode with the given pairs.
  let pairs = pairsStr.toPairs

  mSelf.simulator[].reset true
  mSelf.simulator[].pairs = pairs
  mSelf.simulator[].originalPairs = pairs

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
  ## Handler for keyboard input.
  ## Returns `true` if any action is executed.
  if event == initKeyEvent("KeyQ", shift = true):
    mSelf.toggleFocus
    return true

  if mSelf.focusSimulator:
    return mSelf.simulator[].operate event

  if event == initKeyEvent("KeyA"):
    mSelf.prevResultPage
    return true
  if event == initKeyEvent("KeyD"):
    mSelf.nextResultPage
    return true

  result = false

# ------------------------------------------------
# Backend-specific Implementation
# ------------------------------------------------

when defined(js):
  import std/[dom, sugar]
  import karax/[karax, karaxdsl, vdom]
  import ../private/app/marathon/web/[controller, pagination, searchbar,
                                      searchresult, simulator]

  # ------------------------------------------------
  # JS - Keyboard Handler
  # ------------------------------------------------

  proc runKeyboardEventHandler*(mSelf; event: KeyEvent) {.inline.} =
    ## Keyboard event handler.
    let needRedraw = mSelf.operate event
    if needRedraw and not kxi.surpressRedraws:
      kxi.redraw

  proc runKeyboardEventHandler*(mSelf; event: dom.Event) {.inline.} =
    ## Keybaord event handler.
    # HACK: somehow this assertion fails
    # assert event of KeyboardEvent
    mSelf.runKeyboardEventHandler cast[KeyboardEvent](event).toKeyEvent

  proc initKeyboardEventHandler*(mSelf): (event: dom.Event) -> void {.inline.} =
    ## Returns the keyboard event handler.
    (event: dom.Event) => mSelf.runKeyboardEventHandler event

  # ------------------------------------------------
  # JS - Node
  # ------------------------------------------------

  proc initMarathonNode*(mSelf; id: string): VNode {.inline.} =
    ## Returns the node of marathon manager.
    ## `id` is shared with other node-creating procedures and need to be unique.
    buildHtml(tdiv(class = "columns is-mobile")):
      tdiv(class = "column is-narrow"):
        mSelf.initMarathonSimulatorNode id
      tdiv(class = "column is-narrow"):
        tdiv(class = "block"):
          mSelf.initMarathonSearchBarNode id
          mSelf.initMarathonControllerNode
        if mSelf.matchPairsStrsSeq.len > 0:
          tdiv(class = "block"):
            mSelf.initMarathonPaginationNode
          tdiv(class = "block"):
            mSelf.initMarathonSearchResultNode

  proc initMarathonNode*(mSelf; setKeyHandler = true; wrapSection = true;
                         id = ""): VNode {.inline.} =
    ## Returns the node of marathon manager.
    ## `id` is shared with other node-creating procedures and need to be unique.
    if setKeyHandler:
      document.onkeydown = mSelf.initKeyboardEventHandler

    if wrapSection:
      result = buildHtml(section(class = "section")):
        mSelf.initMarathonNode id
    else:
      result = mSelf.initMarathonNode id
