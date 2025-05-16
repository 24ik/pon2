## This module implements the select control.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import nigui
import ./[requirement]
import ../../[misc]
import ../../../../app/[color, simulator]
import ../../../../core/[rule]

type SelectControl* = ref object of LayoutContainer ## Select control.
  simulator: Simulator

proc modeHandler(
    control: SelectControl,
    event: ClickEvent,
    mode: SimulatorMode,
    reqControl: RequirementControl,
) {.inline.} =
  ## Changes the simulator mode.
  const ModeToIndex: array[SimulatorMode, Natural] = [0, 1, 2, 3]

  control.simulator.mode = mode

  for mode2 in SimulatorMode:
    control.childControls[0].childControls[ModeToIndex[mode2]].backgroundColor =
      if mode2 == mode: SelectColor.toNiguiColor else: DefaultColor.toNiguiColor

  reqControl.updateRequirementControl event
  event.control.parentWindow.control.forceRedraw

proc ruleHandler(control: SelectControl, event: ClickEvent, rule: Rule) {.inline.} =
  ## Changes the rule.
  const RuleToIndex: array[Rule, Natural] = [0, 1]

  control.simulator.rule = rule

  for rule2 in Rule:
    control.childControls[1].childControls[RuleToIndex[rule2]].backgroundColor =
      if rule2 == rule: SelectColor.toNiguiColor else: DefaultColor.toNiguiColor

  event.control.parentWindow.control.forceRedraw

proc kindHandler(
    control: SelectControl,
    event: ClickEvent,
    kind: SimulatorKind,
    reqControl: RequirementControl,
) {.inline.} =
  ## Changes the simulator kind.
  const KindToIndex: array[SimulatorKind, Natural] = [0, 1]

  control.simulator.kind = kind

  for kind2 in SimulatorKind:
    control.childControls[2].childControls[KindToIndex[kind2]].backgroundColor =
      if kind2 == kind: SelectColor.toNiguiColor else: DefaultColor.toNiguiColor

  reqControl.updateRequirementControl event
  event.control.parentWindow.control.forceRedraw

func newModeHandler(
    control: SelectControl, mode: SimulatorMode, reqControl: RequirementControl
): (event: ClickEvent) -> void =
  ## Returns the mode handler.
  # NOTE: cannot inline due to lazy evaluation
  (event: ClickEvent) => control.modeHandler(event, mode, reqControl)

func newRuleHandler(control: SelectControl, rule: Rule): (event: ClickEvent) -> void =
  ## Returns the rule handler.
  # NOTE: cannot inline due to lazy evaluation
  (event: ClickEvent) => control.ruleHandler(event, rule)

func newKindHandler(
    control: SelectControl, kind: SimulatorKind, reqControl: RequirementControl
): (event: ClickEvent) -> void =
  ## Returns the kind handler.
  # NOTE: cannot inline due to lazy evaluation
  (event: ClickEvent) => control.kindHandler(event, kind, reqControl)

proc newSelectControl*(
    simulator: Simulator, reqControl: RequirementControl
): SelectControl {.inline.} =
  ## Returns a select control.
  result = new SelectControl
  result.init
  result.layout = Layout_Vertical

  result.simulator = simulator

  # mode
  let modeButtons = newLayoutContainer Layout_Horizontal
  result.add modeButtons

  let
    playButton = newColorButton "プレイ"
    editButton = newColorButton "編集"
  modeButtons.add playButton
  modeButtons.add editButton

  playButton.onClick = result.newModeHandler(Play, reqControl)
  editButton.onClick = result.newModeHandler(Edit, reqControl)

  # rule
  let ruleButtons = newLayoutContainer Layout_Horizontal
  result.add ruleButtons

  let
    tsuButton = newColorButton "通"
    waterButton = newColorButton "水中"
  ruleButtons.add tsuButton
  ruleButtons.add waterButton

  tsuButton.onClick = result.newRuleHandler Tsu
  waterButton.onClick = result.newRuleHandler Water

  # kind
  let kindButtons = newLayoutContainer Layout_Horizontal
  result.add kindButtons

  let
    regularButton = newColorButton "とこ"
    nazoButton = newColorButton "なぞ"
  kindButtons.add regularButton
  kindButtons.add nazoButton

  regularButton.onClick = result.newKindHandler(Regular, reqControl)
  nazoButton.onClick = result.newKindHandler(Nazo, reqControl)

  # set color
  case simulator.mode
  of PlayEditor:
    playButton.backgroundColor = SelectColor.toNiguiColor
  of Edit:
    editButton.backgroundColor = SelectColor.toNiguiColor
  of Play, View:
    assert false

  case simulator.rule
  of Tsu:
    tsuButton.backgroundColor = SelectColor.toNiguiColor
  of Water:
    waterButton.backgroundColor = SelectColor.toNiguiColor

  case simulator.kind
  of Regular:
    regularButton.backgroundColor = SelectColor.toNiguiColor
  of Nazo:
    nazoButton.backgroundColor = SelectColor.toNiguiColor

  # set enabled
  let editorMode = simulator.mode in {PlayEditor, Edit}
  playButton.enabled = editorMode
  editButton.enabled = editorMode
  tsuButton.enabled = editorMode
  waterButton.enabled = editorMode
  regularButton.enabled = editorMode
  nazoButton.enabled = editorMode
