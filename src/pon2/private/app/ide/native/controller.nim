## This module implements the editor controller control.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import nigui
import ../../[misc]
import ../../../../app/[color, ide]

type EditorControllerControl* = ref object of LayoutContainer not nil
  ## Editor controller control.
  ide: Ide

func newToggleHandler(control: EditorControllerControl): (event: ClickEvent) -> void =
  ## Returns the toggler handler.
  # NOTE: inlining does not work due to lazy evaluation
  (event: ClickEvent) => (
    block:
      control.ide.toggleFocus
      control.childControls[0].backgroundColor = toNiguiColor(
        if control.ide.focusAnswer: SelectColor else: DefaultColor
      )
  )

func newSolveHandler(control: EditorControllerControl): (event: ClickEvent) -> void =
  ## Returns the solve handler.
  # NOTE: inlining does not work due to lazy evaluation
  (event: ClickEvent) => control.ide.solve

proc newEditorControllerControl*(
    ide: Ide
): EditorControllerControl {.inline.} =
  ## Returns a new editor controller control.
  {.push warning[ProveInit]: off.}
  result.new
  {.pop.}
  result.init
  result.layout = Layout_Horizontal

  result.ide = ide

  let
    toggleButton = newColorButton "解答を操作"
    solveButton = newButton "解探索"
  result.add toggleButton
  result.add solveButton

  toggleButton.onClick = result.newToggleHandler
  solveButton.onClick = result.newSolveHandler

  # set color
  toggleButton.backgroundColor =
    toNiguiColor(if ide.focusAnswer: SelectColor else: DefaultColor)
