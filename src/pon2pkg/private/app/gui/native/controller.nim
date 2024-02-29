## This module implements the editor controller control.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import nigui
import ../../[misc]
import ../../../../app/[color, gui]

type EditorControllerControl* = ref object of LayoutContainer
  ## Editor controller control.
  guiApplication: ref GuiApplication

var globalControl: EditorControllerControl = nil # FIXME: remove global control

proc initToggleHandler(control: EditorControllerControl): (event: ClickEvent) -> void =
  ## Returns the toggler handler.
  # NOTE: inlining does not work due to lazy evaluation
  (event: ClickEvent) => (
    block:
      control.guiApplication[].toggleFocus
      control.childControls[0].backgroundColor = toNiguiColor(
        if control.guiApplication[].focusEditor: SelectColor else: DefaultColor
      )
  )

proc initSolveHandler(control: EditorControllerControl): (event: ClickEvent) -> void =
  ## Returns the solve handler.
  # NOTE: inlining does not work due to lazy evaluation
  (event: ClickEvent) => control.guiApplication[].solve

proc initEditorControllerControl*(
    guiApplication: ref GuiApplication
): EditorControllerControl {.inline.} =
  ## Returns a new editor controller control.
  result = new EditorControllerControl
  result.init
  result.layout = Layout_Horizontal

  doAssert globalControl.isNil
  globalControl = result

  result.guiApplication = guiApplication

  let
    toggleButton = initColorButton "解答を操作"
    solveButton = newButton "解探索"
  result.add toggleButton
  result.add solveButton

  toggleButton.onClick = result.initToggleHandler
  solveButton.onClick = result.initSolveHandler

  # set color
  toggleButton.backgroundColor =
    toNiguiColor(if guiApplication[].focusEditor: SelectColor else: DefaultColor)
