## This module implements the replay controller control.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import nigui
import ../../../../apppkg/[editorpermuter, misc]

type ReplayControllerControl* = ref object of LayoutContainer
  ## Replay controller control.
  editorPermuter: ref EditorPermuter

var globalControl: ReplayControllerControl = nil # FIXME: remove global control

proc initToggleHandler(control: ReplayControllerControl):
    (event: ClickEvent) -> void =
  ## Returns the toggler handler.
  # NOTE: inlining does not work due to lazy evaluation
  (event: ClickEvent) => (block:
    control.editorPermuter[].toggleFocus
    control.childControls[0].backgroundColor = toNiguiColor(
      if control.editorPermuter[].focusReplay: SelectColor else: DefaultColor))

proc initSolveHandler(control: ReplayControllerControl):
    (event: ClickEvent) -> void =
  ## Returns the solve handler.
  # NOTE: inlining does not work due to lazy evaluation
  (event: ClickEvent) => control.editorPermuter[].solve

proc initReplayControllerControl*(editorPermuter: ref EditorPermuter):
    ReplayControllerControl {.inline.} =
  ## Returns a new replay controller control.
  result = new ReplayControllerControl
  result.init
  result.layout = Layout_Horizontal

  doAssert globalControl.isNil
  globalControl = result

  result.editorPermuter = editorPermuter

  let
    toggleButton = initColorButton "解答を操作"
    solveButton = newButton "解探索"
  result.add toggleButton
  result.add solveButton

  toggleButton.onClick = result.initToggleHandler
  solveButton.onClick = result.initSolveHandler

  # set color
  toggleButton.backgroundColor = toNiguiColor(
    if editorPermuter[].focusReplay: SelectColor else: DefaultColor)
