## This module implements helper functions for rendering.
##

{.experimental: "strictDefs".}

import std/[options, strformat, uri]
import ../../corepkg/[cell, field, misc, pair, position]
import ../../nazopuyopkg/[mark]
import ../../simulatorpkg/[simulator]

type Color* = object
  red*: byte
  green*: byte
  blue*: byte
  alpha*: byte = 255

const
  SelectColor* = Color(red: 0, green: 209, blue: 178)
  GhostColor* = Color(red: 230, green: 230, blue: 230)
  WaterColor* = Color(red: 135, green: 206, blue: 250)
  DefaultColor* = Color(red: 255, green: 255, blue: 255)

# ------------------------------------------------
# Field
# ------------------------------------------------

when defined(js):
  proc isMobile: bool {.importjs:
    "navigator.userAgent.match(/iPhone|Android.+Mobile/)".}

proc fieldCellBackgroundColor*(
    simulator: Simulator, row: Row, col: Column): Color {.inline.} =
  ## Returns the cell's background color in the field.
  let hideCursor = when defined(js): isMobile() else: false

  result =
    if (
      not hideCursor and simulator.mode == Edit and
      simulator.editing.focusField and
      (row, col) == simulator.editing.field): SelectColor
    elif row == Row.low: GhostColor
    elif simulator.rule == Water and row in WaterRow.low..WaterRow.high:
      WaterColor
    else: DefaultColor

# ------------------------------------------------
# Pairs
# ------------------------------------------------

func needPairPointer*(simulator: Simulator, idx: Natural): bool {.inline.} =
  ## Returns `true` if it is need to show the pointer to the pair.
  simulator.mode != Edit and simulator.state == Stable and
  simulator.next.index == idx

proc pairCellBackgroundColor*(
    simulator: Simulator, idx: Natural, axis: bool): Color {.inline.} =
  ## Returns the cell's background color in the pairs.
  let hideCursor = when defined(js): isMobile() else: false

  result =
    if (
      not hideCursor and simulator.mode == Edit and
      not simulator.editing.focusField and
      (idx, axis) == simulator.editing.pair): SelectColor
    else: DefaultColor

# ------------------------------------------------
# Next Pair
# ------------------------------------------------

func nextPairCell*(simulator: Simulator, idx: range[-1..1], col: Column): Cell
                  {.inline.} =
  ## Returns the cell in the next pairs.
  let pos = simulator.next.position

  result =
    if simulator.state != Stable: None
    elif simulator.pairs.len == 0: None
    elif idx == 0 and col == pos.axisColumn:
      simulator.pairs.peekFirst.axis
    elif (
      # Up, Down
      (col == pos.axisColumn and (
        (idx == -1 and pos.childDirection == Up) or
        (idx == 1 and pos.childDirection == Down))) or
      # Right, Left
      (idx == 0 and (
        (col == pos.axisColumn.succ and pos.childDirection == Right) or
        (col == pos.axisColumn.pred and pos.childDirection == Left)))
    ):
      simulator.pairs.peekFirst.child
    else: None

# ------------------------------------------------
# Immediate Pairs
# ------------------------------------------------

func immediateNextPairCell*(simulator: Simulator, axis: bool): Cell
                           {.inline.} =
  ## Returns the next-pair's cell in the immediate pairs.
  if simulator.pairs.len <= 1:
    return None

  let pair = simulator.pairs[1]
  result = if axis: pair.axis else: pair.child

func immediateDoubleNextPairCell*(simulator: Simulator, axis: bool): Cell
                                 {.inline.} =
  ## Returns the double-next-pair's cell in the immediate pairs.
  if simulator.pairs.len <= 2:
    return None

  let pair = simulator.pairs[2]
  result = if axis: pair.axis else: pair.child

# ------------------------------------------------
# Message
# ------------------------------------------------

const
  DeadMessage = "ばたんきゅ〜"
  NazoMessages: array[MarkResult, string] = [
    "クリア！", "", "ばたんきゅ〜", "不可能な設置", "設置スキップ", "未対応"]

func getMessage*(simulator: Simulator): string {.inline.} =
  ## Returns the message.
  case simulator.kind
  of Regular:
    if simulator.state != Stable: ""
    else:
      simulator.withField:
        if field.isDead: DeadMessage else: ""
  of Nazo:
    simulator.withOriginalNazoPuyo:
      NazoMessages[
        simulator.positions[0..<simulator.next.index].mark originalNazoPuyo]

# ------------------------------------------------
# X
# ------------------------------------------------

const RuleDescriptions: array[Rule, string] = ["通", "すいちゅう"]

{.push warning[ProveInit]: off.}
func makeXLink(text = "", hashTag = none string, uri = none Uri): Uri
              {.inline.} =
  ## Returns the URI for posting to X.
  result = initUri()
  result.scheme = "https"
  result.hostname = "twitter.com"
  result.path = "/intent/tweet"

  var queries = @[
    ("ref_src", "twsrc^tfw|twcamp^buttonembed|twterm^share|twgr^"),
    ("text", text)]
  if hashTag.isSome:
    queries.add ("hashtags", hashTag.get)
  if uri.isSome:
    queries.add ("url", $uri.get)
  result.query = queries.encodeQuery
{.pop.}

func toXLink*(simulator: Simulator, withPositions: bool): Uri {.inline.} =
  ## Returns the URI for posting to X.
  {.push warning[ProveInit]: off.}
  var
    text = ""
    hashTag = none string
  {.pop.}

  if simulator.kind == Nazo:
    let
      ruleStr = RuleDescriptions[simulator.rule]
      moveCountStr = $simulator.pairs.len
      reqStr = $simulator.requirement

    text = &"{ruleStr}・{moveCountStr}手・{reqStr}"
    hashTag = some "なぞぷよ"

  result = makeXLink(text, hashTag, some simulator.toUri withPositions)
