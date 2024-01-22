## This module implements editor-permuters.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[options, sequtils]
import ./[misc, simulator]
import ../corepkg/[environment, field, misc, pair, position]
import ../nazopuyopkg/[nazopuyo]
import ../private/[misc]

when defined(js):
  import std/[uri]
  import karax/[karax, karaxdsl, vdom]
  import ../private/[webworker]
else:
  {.push warning[Deprecated]: off.}
  import std/[sugar, threadpool]
  import nigui
  import ../nazopuyopkg/[solve]
  {.pop.}

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

  {.push warning[ProveInit]: off.}
  result.answers = none seq[Positions]
  result.answerIdx = 0
  {.pop.}

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

  {.push warning[ProveInit]: off.}
  result.answers = none seq[Positions]
  result.answerIdx = 0
  {.pop.}

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

func toggleFocus*(mSelf) {.inline.} = mSelf.focusAnswer.toggle
  ## Toggles focusing answer or not.

# ------------------------------------------------
# Solve
# ------------------------------------------------

proc updateAnswer[F: TsuField or WaterField](mSelf; nazo: NazoPuyo[F])
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

proc solve*(editorPermuter: var EditorPermuter) {.inline.} =
  ## Solves the nazo puyo.
  if (editorPermuter.solving or editorPermuter.editSimulator[].kind != Nazo):
    return

  editorPermuter.solving = true

  editorPermuter.editSimulator[].withNazoPuyo:
    when defined(js):
      proc showAnswers(returnCode: WorkerReturnCode, messages: seq[string]) =
        case returnCode
        of Success:
          editorPermuter.answers = some messages.mapIt it.parsePositions Izumiya
          editorPermuter.updateAnswer nazoPuyo
          editorPermuter.solving = false

          if not kxi.surpressRedraws:
            kxi.redraw
        of Failure:
          discard

      showAnswers.initWorker.run $nazoPuyo.toUri
    else:
      # FIXME: make asynchronous
      # FIXME: redraw
      editorPermuter.answers = some nazoPuyo.solve
      editorPermuter.updateAnswer nazoPuyo
      editorPermuter.solving = false

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
  import std/[dom, sugar]
  import ../private/app/web/answer/[controller, pagination, simulator]

  # ------------------------------------------------
  # JS - Keyboard Handler
  # ------------------------------------------------

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
  # JS - Node
  # ------------------------------------------------

  proc initEditorPermuterNode(mSelf; id: string): VNode {.inline.} =
    ## Returns the editor&permuter node without the external section.
    ## `id` is shared with other node-creating procedures and need to be unique.
    let simulatorNode = mSelf.editSimulator[].initSimulatorNode(
      setKeyHandler = false, id = id)

    result = buildHtml(tdiv(class = "columns is-mobile is-variable is-1")):
      tdiv(class = "column is-narrow"):
        simulatorNode
      if mSelf.editor:
        tdiv(class = "column is-narrow"):
          section(class = "section"):
            tdiv(class = "block"):
              mSelf.initAnswerControllerNode
            if mSelf.answers.isSome:
              tdiv(class = "block"):
                mSelf.initAnswerPaginationNode
              if mSelf.answers.isSome:
                tdiv(class = "block"):
                  mSelf.initAnswerSimulatorNode

  proc initEditorPermuterNode*(mSelf; setKeyHandler = true, wrapSection = true,
                               id = ""): VNode {.inline.} =
    ## Returns the editor&permuter node.
    ## `id` is shared with other node-creating procedures and need to be unique.
    if setKeyHandler:
      document.onkeydown = mSelf.initKeyboardEventHandler

    if wrapSection:
      result = buildHtml(section(class = "section")):
        mSelf.initEditorPermuterNode id
    else:
      result = mSelf.initEditorPermuterNode id

  proc initEditorPermuterNode*[F: TsuField or WaterField](
      nazoEnv: NazoPuyo[F] or Environment[F], positions: Positions, mode = Play,
      editor = false, setKeyHandker = true, wrapSection = true, id = ""): VNode
      {.inline.} =
    ## Returns the editor&permuter node.
    ## `id` is shared with other node-creating procedures and need to be unique.
    var editorPermuter = nazoEnv.initEditorPermuter(positions, mode, editor)
    result = editorPermuter.initEditorPermuterNode(setKeyHandker, wrapSection,
                                                   id)

  proc initEditorPermuterNode*[F: TsuField or WaterField](
      nazoEnv: NazoPuyo[F] or Environment[F], mode = Play, editor = false,
      setKeyHandker = true, wrapSection = true, id = ""): VNode {.inline.} =
    ## Returns the editor&permuter node.
    ## `id` is shared with other node-creating procedures and need to be unique.
    var editorPermuter = nazoEnv.initEditorPermuter(mode, editor)
    result = editorPermuter.initEditorPermuterNode(setKeyHandker, wrapSection,
                                                   id)
else:
  import ../private/app/native/answer/[controller, pagination, simulator]

  type
    EditorPermuterControl* = ref object of LayoutContainer
      ## Root control of the editor&permuter.
      editorPermuter*: ref EditorPermuter

    EditorPermuterWindow* = ref object of WindowImpl
      ## Application window for the editor&permuter.
      editorPermuter*: ref EditorPermuter

  # ------------------------------------------------
  # Native - Keyboard Handler
  # ------------------------------------------------

  proc runKeyboardEventHandler*(
      window: EditorPermuterWindow, event: KeyboardEvent,
      keys = downKeys()) {.inline.} =
    ## Keyboard event handler.
    let needRedraw = window.editorPermuter[].operate event.toKeyEvent keys
    if needRedraw:
      event.window.control.forceRedraw

  proc keyboardEventHandler(event: KeyboardEvent) =
    ## Keyboard event handler.
    let rawWindow = event.window
    assert rawWindow of EditorPermuterWindow

    cast[EditorPermuterWindow](rawWindow).runKeyboardEventHandler event

  func initKeyboardEventHandler*: (event: KeyboardEvent) -> void {.inline.} =
    ## Returns the keyboard event handler.
    keyboardEventHandler

  # ------------------------------------------------
  # Native - Control
  # ------------------------------------------------

  proc initEditorPermuterControl*(editorPermuter: ref EditorPermuter):
      EditorPermuterControl {.inline.} =
    ## Returns the editor&permuter control.
    result = new EditorPermuterControl
    result.init
    result.layout = Layout_Horizontal

    result.editorPermuter = editorPermuter

    # col=0
    let simulatorControl = editorPermuter[].editSimulator.initSimulatorControl
    result.add simulatorControl

    # col=1
    let secondCol = newLayoutContainer Layout_Vertical
    result.add secondCol

    secondCol.padding = 10.scaleToDpi
    secondCol.spacing = 10.scaleToDpi

    secondCol.add editorPermuter.initAnswerControllerControl
    secondCol.add editorPermuter.initAnswerPaginationControl
    secondCol.add editorPermuter.initAnswerSimulatorControl

  proc initEditorPermuterWindow*(
      editorPermuter: ref EditorPermuter, title = "Pon!通",
      setKeyHandler = true): EditorPermuterWindow {.inline.} =
    ## Returns the editor&permuter window.
    result = new EditorPermuterWindow
    result.init

    result.editorPermuter = editorPermuter

    result.title = title
    result.resizable = false
    if setKeyHandler:
      result.onKeyDown = keyboardEventHandler

    let rootControl = editorPermuter.initEditorPermuterControl
    result.add rootControl

    when defined(windows):
      # HACK: somehow this adjustment is needed on Windows
      # TODO: better implementation
      result.width = (rootControl.naturalWidth.float * 1.1).int
      result.height = (rootControl.naturalHeight.float * 1.1).int
    else:
      result.width = rootControl.naturalWidth
      result.height = rootControl.naturalHeight
