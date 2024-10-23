## This module implements the IDE for web.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, sugar]
import karax/[karax, karaxdsl, kdom, vdom]
import ../[ide, key, simulator]
import ../simulator/[web]
import
  ../../private/app/ide/web/[answer, controller, pagination, settings, share, progress]

# ------------------------------------------------
# Keyboard Handler
# ------------------------------------------------

proc runKeyboardEventHandler*(
    self: Ide, event: KeyEvent
): bool {.inline, discardable.} =
  ## Runs the keyboard event handler.
  ## Returns `true` if any action is executed.
  result = self.operate event
  if result and not kxi.surpressRedraws:
    kxi.redraw

proc runKeyboardEventHandler*(self: Ide, event: Event): bool {.inline, discardable.} =
  ## Keybaord event handler.
  # assert event of KeyboardEvent # HACK: somehow this fails

  result = self.runKeyboardEventHandler cast[KeyboardEvent](event).toKeyEvent
  if result:
    event.preventDefault

func newKeyboardEventHandler*(self: Ide): (event: Event) -> void {.inline.} =
  ## Returns the keyboard event handler.
  (event: Event) => (discard self.runKeyboardEventHandler event)

# ------------------------------------------------
# Node
# ------------------------------------------------

const
  MainSimulatorIdPrefix = "pon2-ide-mainsimulator-"
  AnswerSimulatorIdPrefix = "pon2-ide-answersimulator-"
  SettingsIdPrefix = "pon2-ide-settings-"
  ShareIdPrefix = "pon2-ide-share-"
  AnswerShareIdPrefix = "pon2-ide-share-answer-"

proc newIdeNode(self: Ide, id: string): VNode {.inline.} =
  ## Returns the IDE node without the external section.
  let
    simulatorNode = self.simulator.newSimulatorNode(
      wrapSection = false, id = &"{MainSimulatorIdPrefix}{id}"
    )
    settingsId = &"{SettingsIdPrefix}{id}"

  result = buildHtml(tdiv(class = "columns is-mobile is-variable is-1")):
    tdiv(class = "column is-narrow"):
      tdiv(class = "block"):
        simulatorNode
      tdiv(class = "block"):
        self.newShareNode(&"{ShareIdPrefix}{id}", false)
    if self.simulator.mode in {PlayEditor, Edit} and self.simulator.kind == Nazo:
      tdiv(class = "column is-narrow"):
        section(class = "section"):
          tdiv(class = "block"):
            self.newEditorControllerNode settingsId
          tdiv(class = "block"):
            self.newEditorSettingsNode settingsId
          if self.progressBarData.total > 0:
            self.newEditorProgressBarNode
          if self.answerData.hasData:
            tdiv(class = "block"):
              self.newEditorPaginationNode
            if self.answerData.pairsPositionsSeq.len > 0:
              tdiv(class = "block"):
                self.newAnswerSimulatorNode &"{AnswerSimulatorIdPrefix}{id}"
              tdiv(class = "block"):
                self.newShareNode(&"{AnswerShareIdPrefix}{id}", true)

proc newIdeNode*(
    self: Ide, setKeyHandler = true, wrapSection = true, id = ""
): VNode {.inline.} =
  ## Returns the IDE node.
  if setKeyHandler:
    document.onkeydown = self.newKeyboardEventHandler

  let node = self.newIdeNode id

  if wrapSection:
    result = buildHtml(section(class = "section")):
      node
  else:
    result = node
