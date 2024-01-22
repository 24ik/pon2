## This module implements the answer controller control.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import nigui
import ../../../../apppkg/[editorpermuter, misc]

type AnswerControllerControl* = ref object of LayoutContainer
  ## Answer controller control.
  editorPermuter: ref EditorPermuter

var globalControl: AnswerControllerControl = nil # FIXME: remove global control

proc initToggleHandler(control: AnswerControllerControl):
    (event: ClickEvent) -> void =
  ## Returns the toggler handler.
  # NOTE: inlining does not work due to lazy evaluation
  (event: ClickEvent) => (block:
    control.editorPermuter[].toggleFocus
    control.childControls[0].backgroundColor = toNiguiColor(
      if control.editorPermuter[].focusAnswer: SelectColor else: DefaultColor))

proc initSolveHandler(control: AnswerControllerControl):
    (event: ClickEvent) -> void =
  ## Returns the solve handler.
  # NOTE: inlining does not work due to lazy evaluation
  (event: ClickEvent) => control.editorPermuter[].solve

proc initAnswerControllerControl*(editorPermuter: ref EditorPermuter):
    AnswerControllerControl {.inline.} =
  ## Returns a new answer controller control.
  result = new AnswerControllerControl
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
    if editorPermuter[].focusAnswer: SelectColor else: DefaultColor)
