## This module implements the editor controller control.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import nigui
import ../../../../../apppkg/[editorpermuter, misc]

type EditorControllerControl* = ref object of LayoutContainer
  ## Editor controller control.
  editorPermuter: ref EditorPermuter

var globalControl: EditorControllerControl = nil # FIXME: remove global control

proc initToggleHandler(control: EditorControllerControl):
    (event: ClickEvent) -> void =
  ## Returns the toggler handler.
  # NOTE: inlining does not work due to lazy evaluation
  (event: ClickEvent) => (block:
    control.editorPermuter[].toggleFocus
    control.childControls[0].backgroundColor = toNiguiColor(
      if control.editorPermuter[].focusEditor: SelectColor else: DefaultColor))

proc initSolveHandler(control: EditorControllerControl):
    (event: ClickEvent) -> void =
  ## Returns the solve handler.
  # NOTE: inlining does not work due to lazy evaluation
  (event: ClickEvent) => control.editorPermuter[].solve

proc initEditorControllerControl*(editorPermuter: ref EditorPermuter):
    EditorControllerControl {.inline.} =
  ## Returns a new editor controller control.
  result = new EditorControllerControl
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
    if editorPermuter[].focusEditor: SelectColor else: DefaultColor)
