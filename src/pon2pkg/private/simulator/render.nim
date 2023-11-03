## This module implements helper functions for rendering.
##

{.experimental: "strictDefs".}

import std/[options, strformat, uri]
import ../../simulator/[simulator]
import ../../core/[cell, field, misc, pair, position]
import ../../nazoPuyo/[mark]

# ------------------------------------------------
# Field
# ------------------------------------------------

func fieldCellBackgroundColor*(
    simulator: Simulator, row: Row, col: Column, hideCursor = false):
    tuple[red: byte, green: byte, blue: byte] {.inline.} =
  ## Returns the cell's background color.
  if (
    not hideCursor and
    simulator.mode == IzumiyaSimulatorMode.Edit and
    simulator.showCursor and
    simulator.focusField and
    (row, col) == simulator.selectingFieldPosition): (0, 209, 178)
  elif row == Row.low: (230, 230, 230)
  elif simulator.rule == Water and row in WaterRow.low..WaterRow.high:
    (135, 206, 250)
  else: (255, 255, 255)

# ------------------------------------------------
# Pairs
# ------------------------------------------------

func pairSelected*(simulator: Simulator, idx: Natural,
                   hideCursor = false): bool {.inline.} =
  ## Returns `true` if `pairs[idx]` is selected.
  not hideCursor and
  simulator.mode != IzumiyaSimulatorMode.Edit and
  simulator.state == Stable and
  simulator.nextIdx == idx

func pairCellSelected*(simulator: Simulator, idx: Natural,
                       isAxis: bool): bool {.inline.} =
  ## Returns `true` if the cell in `pairs[idx]` is selected.
  simulator.showCursor and
  not simulator.focusField and
  idx == simulator.selectingPairPosition.index and
  isAxis == simulator.selectingPairPosition.isAxis

# ------------------------------------------------
# Next Pair
# ------------------------------------------------

func nextPairCell*(simulator: Simulator, idx: range[-1 .. 1], col: Column): Cell
                  {.inline.} =
  ## Returns the cell in the next pairs.
  let pos = simulator.nextPosition

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

func immediateNextPairCell*(simulator: Simulator, isAxis: bool): Cell
                           {.inline.} =
  ## Returns the next-pair's cell in the immediate pairs.
  if simulator.pairs.len <= 1:
    return None

  let pair = simulator.pairs[1]
  result = if isAxis: pair.axis else: pair.child

func immediateDoubleNextPairCell*(simulator: Simulator, isAxis: bool): Cell
                                 {.inline.} =
  ## Returns the double-next-pair's cell in the immediate pairs.
  if simulator.pairs.len <= 2:
    return None

  let pair = simulator.pairs[2]
  result = if isAxis: pair.axis else: pair.child

# ------------------------------------------------
# Message
# ------------------------------------------------

const
  DeadMessage = "ばたんきゅ〜"
  NazoMessages: array[MarkResult, string] = [
    "クリア！", "", "ばたんきゅ〜", "不可能な設置", "設置スキップ"]

func getMessage*(simulator: Simulator): string {.inline.} =
  ## Returns the message.
  case simulator.kind
  of Regular:
    if simulator.state != Stable: ""
    else:
      let dead = case simulator.rule
      of Tsu: simulator.environments.tsu.field.isDead
      of Water: simulator.environments.water.field.isDead

      if dead: DeadMessage else: ""
  of IzumiyaSimulatorKind.Nazo:
    let positions = simulator.positions[0..<simulator.nextIdx]

    case simulator.rule
    of Tsu: NazoMessages[simulator.originalTsuNazoPuyo.mark positions]
    of Water: NazoMessages[simulator.originalWaterNazoPuyo.mark positions]

# ------------------------------------------------
# X
# ------------------------------------------------

const RuleDescriptions: array[Rule, string] = ["通", "すいちゅう"]

{.push warning[ProveInit]:off.}
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
  {.push warning[ProveInit]:off.}
  var
    text = ""
    hashTag = none string
  {.pop.}

  if simulator.kind == IzumiyaSimulatorKind.Nazo:
    let
      ruleStr = RuleDescriptions[simulator.rule]
      moveCountStr = $simulator.pairs.len
      reqStr = $simulator.requirement

    text = &"{ruleStr}・{moveCountStr}手・{reqStr}"
    hashTag = some "なぞぷよ"

  result = makeXLink(text, hashTag, some simulator.toUri withPositions)
