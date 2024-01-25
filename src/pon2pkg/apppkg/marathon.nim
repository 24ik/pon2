## This module implements marathon mode.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[critbits, math, os, strutils, sugar]
import ./[misc, simulator]
import ../corepkg/[environment, misc, pair]
import ../private/[misc]

when defined(js):
  import ../nazopuyopkg/[nazopuyo]

type Marathon* = object
  ## Marathon manager.
  simulator*: ref Simulator

  matchPairsSeq*: seq[Pairs]
  matchResultPageCount*: Natural
  matchResultPageIdx*: Natural

  allPairsTree: CritBitTree[void]

  focusSimulator*: bool

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

  result.matchPairsSeq = @[]
  result.matchResultPageCount = 0
  result.matchResultPageIdx = 0
  result.allPairsTree = RawPairsTxt.splitLines.toCritBitTree

  result.focusSimulator = false

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

func toPairs(str: string): Pairs {.inline.} =
  ## Converts the flattened string to the pairs.
  result = initDeque[Pair](128)
  for i in countup(0, 255, 2):
    result.addLast str[i..i.succ].parsePair

func match*(mSelf; prefix: string) {.inline.} =
  ## Updates `mSelf.matchPairsSeq`.
  {.push warning[ProveInit]: off.}
  if prefix == "":
    mSelf.matchPairsSeq = @[]
  else:
    mSelf.matchPairsSeq = collect:
      for str in mSelf.allPairsTree.itemsWithPrefix prefix:
        str.toPairs
  {.pop.}

  mSelf.matchResultPageCount =
    ceil(mSelf.matchPairsSeq.len / MatchResultPairsCountPerPage).Natural
  mSelf.matchResultPageIdx = 0

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
  import std/[dom]
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
        if mSelf.matchPairsSeq.len > 0:
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
