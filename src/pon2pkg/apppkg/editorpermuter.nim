## This module implements the editor and permuter.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[options, sequtils]
import ../corepkg/[environment, field, misc, pair, position]
import ../nazopuyopkg/[nazopuyo]
import ../simulatorpkg/[simulator]

type
  EditorPermuter* = object
    ## Editor and Permuter.
    editSimulator*: ref Simulator
    answerSimulator*: ref Simulator

    answers*: Option[seq[Positions]]
    answerIdx*: Natural

    editor: bool
    focusAnswer*: bool
    solving*: bool

using
  self: EditorPermuter
  mSelf: var EditorPermuter

# ------------------------------------------------
# Constructor
# ------------------------------------------------

proc initEditorPermuter*[F: TsuField or WaterField](
    env: Environment[F], positions: Positions, mode = Play,
    editor = false): EditorPermuter {.inline.} =
  ## Returns a new `EditorManager`.
  ## If `mode` is `Edit`, `editor` will be ignored (*i.e.*, regarded as `true`).
  result.editSimulator = new Simulator
  result.editSimulator[] = env.initSimulator(positions, mode, editor)
  result.answerSimulator = new Simulator
  result.answerSimulator[] = 0.initEnvironment[:F].initSimulator(Replay, editor)

  result.answers = none seq[Positions]
  result.answerIdx = 0

  result.editor = editor
  result.focusAnswer = false
  result.solving = false

proc initEditorPermuter*[F: TsuField or WaterField](
    env: Environment[F], mode = Play, editor = false): EditorPermuter
    {.inline.} =
  ## Returns a new `EditorManager`.
  ## If `mode` is `Edit`, `editor` will be ignored (*i.e.*, regarded as `true`).
  env.initEditorPermuter(Position.none.repeat env.pairs.len, mode, editor)

proc initEditorPermuter*[F: TsuField or WaterField](
    nazo: NazoPuyo[F], positions: Positions, mode = Play,
    editor = false): EditorPermuter {.inline.} =
  ## Returns a new `EditorManager`.
  ## If `mode` is `Edit`, `editor` will be ignored (*i.e.*, regarded as `true`).
  result.editSimulator = new Simulator
  result.editSimulator[] = nazo.initSimulator(positions, mode, editor)
  result.answerSimulator = new Simulator
  result.answerSimulator[] = initNazoPuyo[F]().initSimulator(Replay, editor)

  result.answers = none seq[Positions]
  result.answerIdx = 0

  result.editor = editor
  result.focusAnswer = false
  result.solving = false

proc initEditorPermuter*[F: TsuField or WaterField](
    nazo: NazoPuyo[F], mode = Play, editor = false): EditorPermuter {.inline.} =
  ## Returns a new `EditorManager`.
  ## If `mode` is `Edit`, `editor` will be ignored (*i.e.*, regarded as `true`).
  nazo.initEditorPermuter(Position.none.repeat nazo.moveCount, mode, editor)

# ------------------------------------------------
# Edit - Other
# ------------------------------------------------

func toggleFocus*(mSelf) {.inline.} =
  ## Toggles focusing answer or not.
  mSelf.focusAnswer = not mSelf.focusAnswer

# ------------------------------------------------
# Solve
# ------------------------------------------------

# NOTE: solve procedure should be implemented in backend-specific modules.

proc updateAnswer*[F: TsuField or WaterField](mSelf; nazo: NazoPuyo[F])
                  {.inline.} =
  ## Updates the answer simulator.
  ## This function is assumed to be called after `mSelf.answers` is set.
  assert mSelf.answers.isSome

  if mSelf.answers.get.len > 0:
    mSelf.focusAnswer = true
    mSelf.answerIdx = 0
    mSelf.answerSimulator[] = nazo.initSimulator(
      mSelf.answers.get[mSelf.answerIdx],
      mSelf.answerSimulator[].mode,
      mSelf.answerSimulator[].editor)
  else:
    mSelf.focusAnswer = false

# ------------------------------------------------
# Answer
# ------------------------------------------------

proc nextAnswer*(mSelf) {.inline.} =
  ## Shows the next answer.
  if mSelf.answers.isNone or mSelf.answers.get.len == 0:
    return

  if mSelf.answerIdx == mSelf.answers.get.len.pred:
    mSelf.answerIdx = 0
  else:
    mSelf.answerIdx.inc

  mSelf.answerSimulator[].positions = mSelf.answers.get[mSelf.answerIdx]
  mSelf.answerSimulator[].reset false

proc prevAnswer*(mSelf) {.inline.} =
  ## Shows the previous answer.
  if mSelf.answers.isNone or mSelf.answers.get.len == 0:
    return

  if mSelf.answerIdx == 0:
    mSelf.answerIdx = mSelf.answers.get.len.pred
  else:
    mSelf.answerIdx.dec

  mSelf.answerSimulator[].positions = mSelf.answers.get[mSelf.answerIdx]
  mSelf.answerSimulator[].reset false

# ------------------------------------------------
# Keyboard Operation
# ------------------------------------------------

# import (and export) `EditorPermuter.solve`
when defined(js):
  import ../private/app/web/[controller]
  export solve
else:
  # TODO: placeholder
  proc solve(mSelf) = discard

proc operate*(mSelf; event: KeyEvent): bool {.inline.} =
  ## Handler for keyboard input.
  ## Returns `true` if any action is executed.
  if event == initKeyEvent("KeyQ", shift = true):
    mSelf.toggleFocus
    return true

  if mSelf.focusAnswer:
    # move answer
    if event == initKeyEvent("KeyA"):
      mSelf.prevAnswer
      return true
    if event == initKeyEvent("KeyD"):
      mSelf.nextAnswer
      return true

    return mSelf.answerSimulator[].operate event

  if mSelf.editSimulator[].mode == Edit:
    # solve
    if event == initKeyEvent("Enter"):
      mSelf.solve
      return true

  return mSelf.editSimulator[].operate event

# ------------------------------------------------
# Backend-specific Implementation
# ------------------------------------------------

when defined(js):
  import std/[jsffi, dom, sugar]
  import karax/[karax, karaxdsl, vdom]
  import ../private/app/web/[answer, controller]
  import ../simulatorpkg/[web]

  # ------------------------------------------------
  # JS - Keyboard Handler
  # ------------------------------------------------

  # TODO: refactor; duplicate it
  func toKeyEvent*(event: KeyboardEvent): KeyEvent {.inline.} =
    ## Converts KeyboardEvent to the KeyEvent.
    initKeyEvent($event.code, event.shiftKey, event.ctrlKey, event.altKey,
                event.metaKey)

  proc runKeyboardEventHandler*(mSelf; event: KeyEvent) {.inline.} =
    ## Keyboard event handler.
    let needRedraw = mSelf.operate event
    if needRedraw and not kxi.surpressRedraws:
      kxi.redraw

  proc runKeyboardEventHandler*(mSelf; event: dom.Event) {.inline.} =
    ## Keybaord event handler.
    # HACK: somehow this assertion fails
    # assert event of KeyboardEvent
    mSelf.runKeyboardEventHandler cast[KeyboardEvent](event).toKeyEvent

  proc initKeyboardEventHandler*(mSelf): (event: dom.Event) -> void {.inline.} =
    ## Returns the keyboard event handler.
    (event: dom.Event) => mSelf.runKeyboardEventHandler event

  # ------------------------------------------------
  # JS - DOM
  # ------------------------------------------------

  proc initEditorPermuterDom(mSelf; idx: int): VNode {.inline.} =
    ## Returns the editor&permuter DOM without the external section.
    ## If this procedure is called multiple times,
    ## different `idx` need to be given.
    let simulatorDom = mSelf.editSimulator[].initSimulatorDom(
      setKeyHandler = false, idx = idx)

    result = buildHtml(tdiv(class = "columns is-mobile is-variable is-1")):
      tdiv(class = "column is-narrow"):
        simulatorDom
      tdiv(class = "column is-narrow"):
        section(class = "section"):
          tdiv(class = "block"):
            mSelf.controllerNode
          if mSelf.answers.isSome:
            tdiv(class = "block"):
              mSelf.answerNode

  proc initEditorPermuterDom*(mSelf; setKeyHandler = true, wrapSection = true,
                              idx = 0): VNode {.inline.} =
    ## Returns the editor&permuter DOM.
    ## If this procedure is called multiple times,
    ## different `idx` need to be given.
    if setKeyHandler:
      document.onkeydown = mSelf.initKeyboardEventHandler

    if wrapSection:
      result = buildHtml(section(class = "section")):
        mSelf.initEditorPermuterDom idx
    else:
      result = mSelf.initEditorPermuterDom idx

  proc initEditorPermuterDom*[F: TsuField or WaterField](
      nazoEnv: NazoPuyo[F] or Environment[F], positions: Positions, mode = Play,
      editor = false, setKeyHandker = true, wrapSection = true, idx = 0): VNode
      {.inline.} =
    ## Returns the editor&permuter DOM.
    ## If this procedure is called multiple times,
    ## different `idx` need to be given.
    var editorPermuter = nazoEnv.initEditorPermuter(positions, mode, editor)
    result = editorPermuter.initEditorPermuterDom(setKeyHandker, wrapSection,
                                                  idx)

  proc initEditorPermuterDom*[F: TsuField or WaterField](
      nazoEnv: NazoPuyo[F] or Environment[F], mode = Play, editor = false,
      setKeyHandker = true, wrapSection = true, idx = 0): VNode {.inline.} =
    ## Returns the editor&permuter DOM.
    ## If this procedure is called multiple times,
    ## different `idx` need to be given.
    var editorPermuter = nazoEnv.initEditorPermuter(mode, editor)
    result = editorPermuter.initEditorPermuterDom(setKeyHandker, wrapSection,
                                                  idx)

else:
  discard
