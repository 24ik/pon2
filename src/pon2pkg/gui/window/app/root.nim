## This module implements the root control.
##

import nazopuyo_core
import nigui
import puyo_core

import ./field
import ./firstPair
import ./messages
import ./pairs
import ./requirement
import ./state
import ../resource
import ../../setting/main
import ../../setting/theme

type RootControl* = ref object of LayoutContainer
  ## Root control.
  fieldControl*: FieldControl
  firstPairControl*: FirstPairControl
  messagesControl*: MessagesControl
  pairsControl*: PairsControl
  requirementControl*: RequirementControl

# ------------------------------------------------
# Constructor
# ------------------------------------------------

proc newRootControl*(
  nazo: ref Nazo,
  positions: ref Positions,

  mode: ref Mode,
  state: ref SimulatorState,
  focus: ref Focus,
  inserted: ref bool,
  nextIdx: ref Natural,
  nextPos: ref Position,

  setting: ref Setting,
  resource: ref Resource,
): RootControl {.inline.} =
  ## Returns a new root control.
  result = new RootControl
  result.init
  result.layout = Layout_Vertical

  # member
  result.fieldControl = newFieldControl(nazo, mode, focus, inserted, setting, resource)
  result.firstPairControl = newFirstPairControl(nazo, mode, state, nextIdx, nextPos, setting, resource)
  result.messagesControl = newMessagesControl(setting, resource)
  result.pairsControl = newPairsControl(nazo, positions, mode, focus, inserted, nextIdx, setting, resource)
  result.requirementControl = newRequirementControl(nazo, mode, focus, setting, resource)

  #[
    fieldFirstPairControl

    ---------
    firstPair
    ---------
    field
    ---------
  ]#
  let fieldFirstPairControl = newLayoutContainer Layout_Vertical
  fieldFirstPairControl.add result.firstPairControl
  fieldFirstPairControl.add result.fieldControl

  #[
    envControl

    ---------|-----
    firstPair|
    ---------|pairs
    field    |
    ---------|-----
  ]#
  let envControl = newLayoutContainer Layout_Horizontal
  envControl.add fieldFirstPairControl
  envControl.add result.pairsControl

  #[
    rootControl (result)

    ---------------
    requirement
    ---------|-----
    firstPair|
    ---------|pairs
    field    |
    ---------|-----
    messages
    ---------------
  ]#
  result.add result.requirementControl
  result.add envControl
  result.add result.messagesControl

  # width
  result.requirementControl.width = envControl.naturalWidth
  for control in result.messagesControl.childControls:
    control.width = envControl.naturalWidth
