## This module implements the select control.
##

{.experimental: "strictDefs".}

import std/[sugar]
import nigui
import ./[misc, requirement]
import ../../../corepkg/[misc]
import ../../../simulatorpkg/[simulator]

type SelectControl* = ref object of LayoutContainer
  ## Select control.
  simulator: ref Simulator

proc modeHandler(control: SelectControl, event: ClickEvent,
                 mode: IzumiyaSimulatorMode,
                 reqControl: RequirementControl) {.inline.} =
  ## Changes the simulator mode.
  const ModeToIndex: array[IzumiyaSimulatorMode, Natural] = [1, 0, 2]

  control.simulator[].mode = mode

  for mode2 in IzumiyaSimulatorMode:
    control.childControls[0].childControls[ModeToIndex[mode2]].backgroundColor =
      if mode2 == mode: SelectColor else: DefaultColor

  reqControl.updateRequirementControl event
  event.control.parentWindow.control.forceRedraw

proc ruleHandler(control: SelectControl, event: ClickEvent, rule: Rule)
                {.inline.} =
  ## Changes the rule.
  const RuleToIndex: array[Rule, Natural] = [0, 1]

  control.simulator[].rule = rule

  for rule2 in Rule:
    control.childControls[1].childControls[RuleToIndex[rule2]].backgroundColor =
      if rule2 == rule: SelectColor else: DefaultColor

  event.control.parentWindow.control.forceRedraw

proc kindHandler(control: SelectControl, event: ClickEvent,
                 kind: IzumiyaSimulatorKind,
                 reqControl: RequirementControl) {.inline.} =
  ## Changes the simulator kind.
  const KindToIndex: array[IzumiyaSimulatorKind, Natural] = [0, 1]

  control.simulator[].kind = kind

  for kind2 in IzumiyaSimulatorKind:
    control.childControls[2].childControls[KindToIndex[kind2]].backgroundColor =
      if kind2 == kind: SelectColor else: DefaultColor

  reqControl.updateRequirementControl event
  event.control.parentWindow.control.forceRedraw

func initModeHandler(control: SelectControl, mode: IzumiyaSimulatorMode,
                     reqControl: RequirementControl):
                    (event: ClickEvent) -> void =
  ## Returns the mode handler.
  # NOTE: inline hanler does not work due to specifications
  (event: ClickEvent) => control.modeHandler(event, mode, reqControl)

func initRuleHandler(control: SelectControl, rule: Rule):
    (event: ClickEvent) -> void =
  ## Returns the rule handler.
  # NOTE: inline hanler does not work due to specifications
  (event: ClickEvent) => control.ruleHandler(event, rule)

func initKindHandler(control: SelectControl, kind: IzumiyaSimulatorKind,
                     reqControl: RequirementControl):
                    (event: ClickEvent) -> void =
  ## Returns the kind handler.
  # NOTE: inline hanler does not work due to specifications
  (event: ClickEvent) => control.kindHandler(event, kind, reqControl)

proc initSelectControl*(simulator: ref Simulator,
                        reqControl: RequirementControl): SelectControl
                       {.inline.} =
  ## Returns a select control.
  result = new SelectControl
  result.init
  result.layout = Layout_Vertical

  result.simulator = simulator

  # mode
  let modeButtons = newLayoutContainer Layout_Horizontal
  result.add modeButtons

  let
    editButton = initColorButton "編集"
    playButton = initColorButton "プレイ"
    replayButton = initColorButton "再生"
  modeButtons.add editButton
  modeButtons.add playButton
  modeButtons.add replayButton

  editButton.onClick = result.initModeHandler(IzumiyaSimulatorMode.Edit,
                                              reqControl)
  playButton.onClick = result.initModeHandler(Play, reqControl)
  replayButton.onClick = result.initModeHandler(Replay, reqControl)

  # rule
  let ruleButtons = newLayoutContainer Layout_Horizontal
  result.add ruleButtons

  let
    tsuButton = initColorButton "通"
    waterButton = initColorButton "水中"
  ruleButtons.add tsuButton
  ruleButtons.add waterButton

  tsuButton.onClick = result.initRuleHandler Tsu
  waterButton.onClick = result.initRuleHandler Water

  # kind
  let kindButtons = newLayoutContainer Layout_Horizontal
  result.add kindButtons

  let
    regularButton = initColorButton "とこ"
    nazoButton = initColorButton "なぞ"
  kindButtons.add regularButton
  kindButtons.add nazoButton

  regularButton.onClick = result.initKindHandler(Regular, reqControl)
  nazoButton.onClick = result.initKindHandler(IzumiyaSimulatorKind.Nazo,
                                              reqControl)

  # set color
  case simulator[].mode
  of IzumiyaSimulatorMode.Edit:
    editButton.backgroundColor = SelectColor
  of Play:
    playButton.backgroundColor = SelectColor
  of Replay:
    replayButton.backgroundColor = SelectColor

  case simulator[].rule
  of Tsu:
    tsuButton.backgroundColor = SelectColor
  of Water:
    waterButton.backgroundColor = SelectColor

  case simulator[].kind
  of Regular:
    regularButton.backgroundColor = SelectColor
  of IzumiyaSimulatorKind.Nazo:
    nazoButton.backgroundColor = SelectColor
