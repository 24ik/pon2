## This module implements the IDE for native backends.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import nigui
import ../[ide, key]
import ../simulator/[native]
import ../../private/app/ide/native/[answer, controller, pagination]

type
  IdeControl* = ref object of LayoutContainer ## Root control of the IDE.

  IdeWindow* = ref object of WindowImpl ## GUI application window.
    ide: Ide

# ------------------------------------------------
# Keyboard Handler
# ------------------------------------------------

proc runKeyboardEventHandler*(
    window: IdeWindow, event: KeyboardEvent, keys = downKeys()
): bool {.inline, discardable.} =
  ## Runs the keyboard event handler.
  ## Returns `true` if any action is executed.
  result = window.ide.operate event.toKeyEvent keys
  if result:
    event.window.control.forceRedraw

proc runKeyboardEventHandler(event: KeyboardEvent): bool {.inline, discardable.} =
  ## Runs the keyboard event handler.
  ## Returns `true` if any action is executed.
  let rawWindow = event.window
  assert rawWindow of IdeWindow

  result = cast[IdeWindow](rawWindow).runKeyboardEventHandler event

func newKeyboardEventHandler*(): (event: KeyboardEvent) -> void {.inline.} =
  ## Returns the keyboard event handler.
  (event: KeyboardEvent) => (discard event.runKeyboardEventHandler)

# ------------------------------------------------
# Control / Window
# ------------------------------------------------

proc newIdeControl*(self: Ide): IdeControl {.inline.} =
  ## Returns the IDE control.
  {.push warning[ProveInit]: off.}
  result.new
  {.pop.}
  result.init
  result.layout = Layout_Horizontal

  # col=0
  let simulatorControl = self.simulator.newSimulatorControl
  result.add simulatorControl

  # col=1
  let secondCol = newLayoutContainer Layout_Vertical
  result.add secondCol

  secondCol.padding = 10.scaleToDpi
  secondCol.spacing = 10.scaleToDpi

  secondCol.add self.newEditorControllerControl
  secondCol.add self.newEditorPaginationControl
  secondCol.add self.newAnswerSimulatorControl

proc newIdeWindow*(
    self: Ide, title = "Pon!通", setKeyHandler = true
): IdeWindow {.inline.} =
  ## Returns the IDE window.
  {.push warning[ProveInit]: off.}
  result.new
  {.pop.}
  result.init

  result.ide = self

  result.title = title
  result.resizable = false
  if setKeyHandler:
    result.onKeyDown = newKeyboardEventHandler()

  let rootControl = self.newIdeControl
  result.add rootControl

  when defined(windows):
    # FIXME: ad hoc adjustment needed on Windows and should be improved
    result.width = (rootControl.naturalWidth.float * 1.1).int
    result.height = (rootControl.naturalHeight.float * 1.1).int
  else:
    result.width = rootControl.naturalWidth
    result.height = rootControl.naturalHeight
