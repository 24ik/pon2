## This module implements handlers.
##

import deques
import options
import sequtils
import std/setutils
import strformat
import sugar
import threadpool

import nazopuyo_core
import nigui
import nigui/msgBox
import puyo_core
import tiny_sqlite

import ./window
import ./field
import ./messages
import ./pairs
import ./state
import ../../setting/key
import ../../setting/main
import ../../../core/db
import ../../../core/solve

# ------------------------------------------------
# Property
# ------------------------------------------------

func appWindow(event: CloseClickEvent or KeyboardEvent): AppWindow {.inline.} =
  ## Returns the window from the :code:`event`.
  let window = event.window
  assert window of AppWindow
  return cast[AppWindow](window)

# ------------------------------------------------
# Edit
# ------------------------------------------------

func save(window: AppWindow, nazo = Nazo.none) {.inline.} =
  ## Saves the current state for undo.
  window.undoDeque.addLast if nazo.isSome: nazo.get else: window.nazo[]
  window.redoDeque.clear

func resetRecord(window: AppWindow) {.inline.} =
  ## Resets the record.
  window.recordState = EMPTY
  window.records = @[]
  window.recordIdx = 0
  window.messagesControl.messages[MessageKind.RECORD] = ""

template change(window: AppWindow, body: untyped) =
  ## Performs the pre- and post-processing required when making changes to the state.
  window.save
  body
  window.stableNazo = window.nazo[]
  window.originalNazo = window.nazo[]
  window.resetRecord

# ------------------------------------------------
# Undo / Redo
# ------------------------------------------------

func undo(window: AppWindow) {.inline.} =
  if window.undoDeque.len == 0:
    return

  window.redoDeque.addLast window.nazo[]

  window.nazo[] = window.undoDeque.popLast
  window.stableNazo = window.nazo[]

func redo(window: AppWindow) {.inline.} =
  if window.redoDeque.len == 0:
    return

  window.undoDeque.addLast window.nazo[]

  window.nazo[] = window.redoDeque.popLast
  window.stableNazo = window.nazo[]

# ------------------------------------------------
# Control Operation
# ------------------------------------------------

proc fixPairsControlPositions(window: AppWindow, idx = Natural.none) {.inline.} =
  ## Fixes the length of the pairs control.
  let
    nowControlLen = window.pairsControl.childControls.len
    targetControlLen = window.nazo[].env.pairs.len.succ

  if nowControlLen == targetControlLen:
    return

  if nowControlLen < targetControlLen:
    let addNum = targetControlLen - nowControlLen

    for _ in 0 ..< addNum:
      window.pairsControl.addPairWithInfoControl

    if idx.isSome:
      window.positions[] =
        window.positions[][0 ..< idx.get] & Position.none.repeat(addNum) & window.positions[][idx.get .. ^1]
    else:
      window.positions[] &= Position.none.repeat addNum
  else:
    let removeNum = nowControlLen - targetControlLen

    for _ in 0 ..< removeNum:
      window.pairsControl.removePairWithInfoControl

    if idx.isSome:
      window.positions[] = window.positions[][0 ..< idx.get] & window.positions[][idx.get.succ(removeNum) .. ^1]
    else:
      window.positions[] = window.positions[][0 ..< ^removeNum]

    window.pairsControl.cursor.idx = min(window.pairsControl.cursor.idx, targetControlLen.pred)

func fixRequirement(window: AppWindow) {.inline.} =
  ## Fixes the color and number in the requirement.
  if window.nazo[].req.kind in RequirementKindsWithColor and window.nazo[].req.color.isNone:
    window.nazo[].req.color = some RequirementColor.low
  if window.nazo[].req.kind in RequirementKindsWithNum and window.nazo[].req.num.isNone:
    window.nazo[].req.num = some RequirementNumber.low

# ------------------------------------------------
# Solve
# ------------------------------------------------

func solveTarget(window: AppWindow): tuple[nazo: Nazo, useOriginal: bool] {.inline.} =
  ## Returns the nazo puyo to solve.
  if window.nextIdx[] == window.nazo[].env.pairs.len:
    result.nazo = window.originalNazo
    result.useOriginal = true
  else:
    result.nazo = window.stableNazo
    result.nazo.env.pairs.shrink(fromFirst = window.nextIdx[])

func writeSolutionNum(window: AppWindow) {.inline.} =
  ## Writes the number of solutions to the messages.
  if window.recordState == READY:
    window.messagesControl.messages[MessageKind.RECORD] = &"解の個数：{window.records.len}"

proc solveAndWrite(window: AppWindow) {.inline.} =
  ## Solves the nazo puyo and write the solutions to the messages.
  {.gcsafe.}:
    app.queueMain do:
      window.recordState = WRITING

  let (nazo, useOriginal) = window.solveTarget
  {.gcsafe.}:
    app.queueMain do:
      window.messagesControl.messages[MISC] =
        if useOriginal: "設置前のなぞぷよで解探索します"
        else: "現在の状態のなぞぷよで解探索します"
      window.messagesControl.messages[MessageKind.RECORD] = "解探索中"
      window.messagesControl.forceRedraw

  let records = collect:
    for sol in nazo.solve:
      (nazo: nazo, positions: sol)

  {.gcsafe.}:
    app.queueMain do:
      window.recordState = READY
      window.records = records
      window.writeSolutionNum
      window.messagesControl.forceRedraw

# ------------------------------------------------
# Mark
# ------------------------------------------------

func mark(window: AppWindow) {.inline.} =
  ## Marks the positions and writes the result to the messages.
  case window.originalNazo.mark window.positions[][0 ..< window.nextIdx[]]
  of ACCEPT:
    window.messagesControl.messages[MARK] = "クリア！"
  of WRONG_ANSWER:
    window.messagesControl.messages[MARK] = ""
  of DEAD:
    window.messagesControl.messages[MARK] = "ばたんきゅ〜"
  of IMPOSSIBLE_MOVE:
    window.messagesControl.messages[MARK] = "不可能な設置"
  of SKIP_MOVE:
    window.messagesControl.messages[MARK] = "設置スキップ"
  of URL_ERROR:
    doAssert false

# ------------------------------------------------
# Move
# ------------------------------------------------

func prepareMove(window: AppWindow) {.inline.} =
  ## Initializes the state for moving.
  window.state[] = MOVING
  window.nextPos[] = POS_3U

func prepareNextMove(window: AppWindow) {.inline.} =
  ## Initializes the state for next moving.
  window.stableNazo = window.nazo[]

  window.nextIdx[].inc
  window.prepareMove

  window.mark

func preparePrevMove(window: AppWindow) {.inline.} =
  ## Initializes the state for previous moving.
  window.stableNazo = window.nazo[]

  window.nextIdx[].dec
  window.prepareMove

  window.mark

func forward(window: AppWindow, useNextPos: bool) {.inline.} =
  ## Proceeds the simulator by a step.
  case window.state[]
  of MOVING:
    if window.nextIdx[] >= window.nazo[].env.pairs.len:
      return
  
    if useNextPos:
      window.positions[window.nextIdx[]] = some window.nextPos[]
    let pos = window.positions[window.nextIdx[]]

    if pos.isSome:
      window.nazo[].env.field.put window.nazo[].env.pairs[window.nextIdx[]], pos.get

    if window.nazo[].env.field.willDisappear:
      window.state[] = BEFORE_DISAPPEAR
    else:
      window.save some window.stableNazo
      window.prepareNextMove
  of BEFORE_DISAPPEAR:
    window.nazo[].env.field.disappear
    window.state[] = BEFORE_DROP
  of BEFORE_DROP:
    window.nazo[].env.field.drop

    if window.nazo[].env.field.willDisappear:
      window.state[] = BEFORE_DISAPPEAR
    else:
      window.save some window.stableNazo
      window.prepareNextMove

func backward(window: AppWindow) {.inline.} =
  ## Goes back the simulator by a step.
  case window.state[]
  of MOVING:
    if window.nextIdx[] == 0:
      return

    window.undo
    window.preparePrevMove
  of BEFORE_DISAPPEAR, BEFORE_DROP:
    window.nazo[] = window.stableNazo
    window.prepareMove

# ------------------------------------------------
# Record
# ------------------------------------------------

func playRecord(window: AppWindow) {.inline.} =
  ## Plays the record.
  window.nazo[] = window.records[window.recordIdx].nazo
  window.positions[] = window.records[window.recordIdx].positions
  window.nextIdx[] = 0
  window.prepareMove

  window.messagesControl.messages[MessageKind.RECORD] = &"再生番号：{window.recordIdx.succ}/{window.records.len}"

# ------------------------------------------------
# Handler
# ------------------------------------------------

func insert[T](deque: var Deque[T], item: sink T, idx = 0.Natural) {.inline.} =
  ## Inserts :code:`item` to the :code:`deque` at index :code:`idx`.
  runnableExamples:
    import deques

    var deque = [1, 2, 3].toDeque
    deque.insert 10, 2
    assert $deque == "[1, 2, 10, 3]"

  var s = deque.toSeq
  s.insert item, idx
  deque = s.toDeque

func delete[T](deque: var Deque[T], idx: Natural) {.inline.} =
  ## Deletes the item at index :code:`idx` from the :code:`deque`.
  var s = deque.toSeq
  s.delete idx
  deque = s.toDeque

func succRot[T: Ordinal](x: T): T {.inline.} =
  ## Rotating :code:`succ`.
  runnableExamples:
    let x = int.high.pred
    assert x.succRot == int.high
    assert x.succRot.succRot == int.low

  if x == T.high: T.low else: x.succ

func incRot[T: Ordinal](x: var T) {.inline.} =
  ## Rotating :code:`inc`.
  runnableExamples:
    var x = int.high.pred
    x.incRot
    assert x == int.high
    x.incRot
    assert x == int.low

  x = x.succRot

func predRot[T: Ordinal](x: T): T {.inline.} =
  ## Rotating :code:`pred`.
  runnableExamples:
    let x = int.low.succ
    assert x.predRot == int.low
    assert x.predRot.predRot == int.high

  if x == T.low: T.high else: x.pred

func decRot[T: Ordinal](x: var T) {.inline.} =
  ## Rotating :code:`dec`.
  runnableExamples:
    var x = int.low.succ
    x.decRot
    assert x == int.low
    x.decRot
    assert x == int.high

  x = x.predRot

func parseNum(key: Key): Option[int] {.inline.} =
  ## Returns the integer represented by the :code:`key`.
  ## If the :code:`key` does not represent a number, returns :code:`none(int)`.
  if key.ord in Key_Number0.ord .. Key_Number9.ord:
    return some key.ord - Key_Number0.ord
  elif key.ord in Key_Numpad0.ord .. Key_Numpad9.ord:
    return some key.ord - Key_Numpad0.ord

template redrawIfReturned(window: AppWindow, body: untyped) =
  ## Redraws the :code:`window` only if a :code:`return` statement is executed in the :code:`body`.
  var returned = true
  try:
    body
    returned = false
  finally:
    if returned:
      window.control.forceRedraw

proc copy(window: AppWindow): AppWindow {.inline.} # forward declearation

proc confirmExit(window: AppWindow) {.inline.} =
  ## Displays the exit confirmation window.
  case window.msgBox("ウィンドウを閉じますか？", "", "閉じる [Enter]", "キャンセル [Esc]")
  of 1:
    window.dispose
  else:
    discard

proc exitHandler(event: CloseClickEvent) {.inline.} =
  ## Handler for clicking the close button.
  event.appWindow.confirmExit

proc keyHandler(event: KeyboardEvent, keySetting: KeySetting) {.inline.} =
  ## Handler for pressing keys.
  let
    pressedKeys = downKeys().toSet

    window = event.appWindow
    fieldControl = window.fieldControl
    messagesControl = window.messagesControl
    pairsControl = window.pairsControl

  # exit
  if keySetting.exit.pressed(event, pressedKeys):
    window.confirmExit
    return

  window.messagesControl.messages[MISC] = ""

  window.redrawIfReturned:
    # copy window
    if keySetting.newWindow.pressed(event, pressedKeys):
      window.copy.show
      return

    case window.mode[]
    of Mode.EDIT:
      # change mode
      if keySetting.mode.pressed(event, pressedKeys):
        window.mode[] = Mode.PLAY
        window.nazo[] = window.stableNazo
        window.undoDeque.clear
        window.redoDeque.clear
        window.prepareMove

        messagesControl.messages[MARK] = ""
        messagesControl.messages[MISC] = "編集モードを抜けました"

        return

      # load from the clipboard
      if keySetting.paste.pressed(event, pressedKeys):
        let newNazo = app.clipboardText.toNazo true
        if newNazo.isSome:
          window.change:
            window.nazo[] = newNazo.get

          window.fixPairsControlPositions
          window.nextIdx[] = 0
          window.prepareMove

          messagesControl.messages[MISC] = "URLを読み込みました"
        else:
          messagesControl.messages[MISC] = "不正なURLが入力されました"

        return

      # save to the clipboard
      if keySetting.copy.pressed(event, pressedKeys):
        app.clipboardText = window.nazo[].toUrl
        messagesControl.messages[MISC] = "URLをコピーしました"

        return

      # change focus
      if keySetting.focus.pressed(event, pressedKeys):
        window.focus[].incRot
        return

      # solve
      if keySetting.solve.pressed(event, pressedKeys):
        case window.recordState
        of EMPTY:
          spawn window.solveAndWrite
        of WRITING:
          discard
        of READY:
          let newWindow = window.copy
          newWindow.mode[] = Mode.RECORD
          newWindow.playRecord
          newWindow.show

        return

      # save to the database
      if keySetting.save.pressed(event, pressedKeys):
        let (nazo, useOriginal) = window.solveTarget
        window.db[].insert nazo
        messagesControl.messages[MISC] = if useOriginal: "設置前のなぞぷよを保存しました" else: "現在のなぞぷよを保存しました"

        return

      # remove from the database
      if keySetting.remove.pressed(event, pressedKeys):
        let
          (nazo, useOriginal) = window.solveTarget
          prefix = if useOriginal: "設置前" else: "現在"
          suffix = if window.db[].delete nazo.toUrl: "を削除しました" else: "は未登録です"
        messagesControl.messages[MISC] = &"{prefix}のなぞぷよ{suffix}"

        return

      # undo
      if keySetting.undo.pressed(event, pressedKeys):
        window.undo
        window.originalNazo = window.nazo[]
        window.fixPairsControlPositions
        window.resetRecord

        return

      # redo
      if keySetting.redo.pressed(event, pressedKeys):
        window.redo
        window.originalNazo = window.nazo[]
        window.fixPairsControlPositions
        window.resetRecord

        return

      # insert
      if keySetting.insert.pressed(event, pressedKeys):
        if window.inserted[]:
          window.inserted[] = false
          messagesControl.messages[MISC] = "挿入モードを抜けました"
        else:
          window.inserted[] = true
          messagesControl.messages[MISC] = "挿入モードに入りました"

        return

      case window.focus[]
      of Focus.FIELD:
        # move cursor
        if keySetting.up.pressed(event, pressedKeys):
          fieldControl.cursor.row.decRot
          return
        if keySetting.right.pressed(event, pressedKeys):
          fieldControl.cursor.col.incRot
          return
        if keySetting.down.pressed(event, pressedKeys):
          fieldControl.cursor.row.incRot
          return
        if keySetting.left.pressed(event, pressedKeys):
          fieldControl.cursor.col.decRot
          return

        # shift
        if keySetting.shiftUp.pressed(event, pressedKeys):
          window.change:
            window.nazo[].env.field.shiftUp
          return
        if keySetting.shiftDown.pressed(event, pressedKeys):
          window.change:
            window.nazo[].env.field.shiftDown
          return
        if keySetting.shiftRight.pressed(event, pressedKeys):
          window.change:
            window.nazo[].env.field.shiftRight
          return
        if keySetting.shiftLeft.pressed(event, pressedKeys):
          window.change:
            window.nazo[].env.field.shiftLeft
          return

        # drop
        if keySetting.drop.pressed(event, pressedKeys):
          window.change:
            window.nazo[].env.field.drop
          return

        # write/remove cell
        let pressedKeyAndCell = [
          (keySetting.none, NONE),
          (keySetting.garbage, Cell.GARBAGE),
          (keySetting.red, Cell.RED),
          (keySetting.green, Cell.GREEN),
          (keySetting.blue, Cell.BLUE),
          (keySetting.yellow, Cell.YELLOW),
          (keySetting.purple, Cell.PURPLE),
        ].filterIt it[0].pressed(event, pressedKeys)
        case pressedKeyAndCell.len
        of 0:
          discard
        of 1:
          window.change:
            let
              cell = pressedKeyAndCell[0][1]
              col = fieldControl.cursor.col
              row = fieldControl.cursor.row

            if cell == NONE:
              if window.inserted[]:
                window.nazo[].env.field.removeSqueeze row, col
              else:
                window.nazo[].env.field[row, col] = NONE
            else:
              if window.inserted[]:
                window.nazo[].env.field.insert row, col, cell
              else:
                window.nazo[].env.field[row, col] = cell

          return
        else:
          doAssert false
      of Focus.PAIRS:
        # move cursor
        if keySetting.up.pressed(event, pressedKeys):
          if pairsControl.cursor.idx == 0:
            pairsControl.cursor.idx = window.nazo[].env.pairs.len
          else:
            pairsControl.cursor.idx.dec

          return
        if keySetting.down.pressed(event, pressedKeys):
          if pairsControl.cursor.idx == window.nazo[].env.pairs.len:
            pairsControl.cursor.idx = 0
          else:
            pairsControl.cursor.idx.inc

          return
        if keySetting.right.pressed(event, pressedKeys) or keySetting.left.pressed(event, pressedKeys):
          pairsControl.cursor.axis = not pairsControl.cursor.axis
          return

        # swap
        if keySetting.shiftRight.pressed(event, pressedKeys) or keySetting.shiftLeft.pressed(event, pressedKeys):
          if pairsControl.cursor.idx < window.nazo[].env.pairs.len:
            window.change:
              window.nazo[].env.pairs[pairsControl.cursor.idx].swap

          return

        # write/remove cell
        let pressedKeyAndColor = [
          (keySetting.red, Cell.RED.ColorPuyo),
          (keySetting.green, Cell.GREEN.ColorPuyo),
          (keySetting.blue, Cell.BLUE.ColorPuyo),
          (keySetting.yellow, Cell.YELLOW.ColorPuyo),
          (keySetting.purple, Cell.PURPLE.ColorPuyo),
        ].filterIt it[0].pressed(event, pressedKeys)
        case pressedKeyAndColor.len
        of 0:
          if keySetting.none.pressed(event, pressedKeys):
            window.change:
              window.nazo[].env.pairs.delete pairsControl.cursor.idx

            window.fixPairsControlPositions

            return
        of 1:
          window.change:
            let
              puyo = pressedKeyAndColor[0][1]
              idx = pairsControl.cursor.idx

            if window.inserted[] or idx == window.nazo[].env.pairs.len:
              window.nazo[].env.pairs.insert makePair(puyo, puyo), idx
            else:
              if pairsControl.cursor.axis:
                window.nazo[].env.pairs[idx].axis = puyo
              else:
                window.nazo[].env.pairs[idx].child = puyo

          window.fixPairsControlPositions

          return
        else:
          doAssert false
      of Focus.REQUIREMENT:
        # kind
        if keySetting.down.pressed(event, pressedKeys):
          window.change:
            window.nazo[].req.kind.incRot
            window.fixRequirement

          return
        if keySetting.up.pressed(event, pressedKeys):
          window.change:
            window.nazo[].req.kind.decRot
            window.fixRequirement

          return

        # color
        if window.nazo[].req.kind in RequirementKindsWithColor:
          let pressedKeyAndColor = [
            (keySetting.garbage, RequirementColor.GARBAGE),
            (keySetting.red, RequirementColor.RED),
            (keySetting.green, RequirementColor.GREEN),
            (keySetting.blue, RequirementColor.BLUE),
            (keySetting.yellow, RequirementColor.YELLOW),
            (keySetting.purple, RequirementColor.PURPLE),
            (keySetting.all, RequirementColor.ALL),
            (keySetting.color, RequirementColor.COLOR),
          ].filterIt it[0].pressed(event, pressedKeys)
          case pressedKeyAndColor.len
          of 0:
            discard
          of 1:
            window.change:
              window.nazo[].req.color = some pressedKeyAndColor[0][1]

            return
          else:
            doAssert false

        # num
        if window.nazo[].req.kind in RequirementKindsWithNum:
          # increment
          if keySetting.right.pressed(event, pressedKeys):
            window.change:
              window.nazo[].req.num = some window.nazo[].req.num.get.succRot

            return

          # decrement
          if keySetting.left.pressed(event, pressedKeys):
            window.change:
              window.nazo[].req.num = some window.nazo[].req.num.get.predRot

            return

          # number input
          let inputNum = event.key.parseNum
          if inputNum.isSome:
            window.change:
              let nowNum = window.nazo[].req.num.get
              window.nazo[].req.num = some RequirementNumber min(
                if nowNum >= 10: nowNum mod 10 * 10 + inputNum.get else: nowNum * 10 + inputNum.get,
                RequirementNumber.high)

            return
    of Mode.PLAY:
      # change mode
      if keySetting.mode.pressed(event, pressedKeys):
        window.mode[] = Mode.EDIT
        window.nazo[] = window.stableNazo
        window.undoDeque.clear
        window.redoDeque.clear
        window.prepareMove

        window.messagesControl.messages[MISC] = "編集モードに入りました"
        window.writeSolutionNum

        return

      # forward
      if keySetting.down.pressed(event, pressedKeys):
        window.forward true
        return

      # backward
      if keySetting.up.pressed(event, pressedKeys):
        window.backward
        return

      if window.state[] != MOVING:
        return

      # move the first pair
      if keySetting.right.pressed(event, pressedKeys):
        window.nextPos[].moveRight
        return
      if keySetting.left.pressed(event, pressedKeys):
        window.nextPos[].moveLeft
        return

      # rotate the first pair
      if keySetting.rotateRight.pressed(event, pressedKeys):
        window.nextPos[].rotateRight
        return
      if keySetting.rotateLeft.pressed(event, pressedKeys):
        window.nextPos[].rotateLeft
        return

      # skip
      if keySetting.skip.pressed(event, pressedKeys):
        if window.nextIdx[] < window.nazo[].env.pairs.len:
          window.positions[][window.nextIdx[]] = none Position
          window.forward false

        return

      # next
      if keySetting.next.pressed(event, pressedKeys):
        window.forward false
        return

    of Mode.RECORD:
      # prev/next record
      if keySetting.right.pressed(event, pressedKeys):
        window.recordIdx = if window.recordIdx == window.records.len.pred: 0 else: window.recordIdx.succ
        window.playRecord
        return
      if keySetting.left.pressed(event, pressedKeys):
        window.recordIdx = if window.recordIdx == 0: window.records.len.pred else: window.recordIdx.pred
        window.playRecord
        return

      # forward
      if keySetting.down.pressed(event, pressedKeys):
        window.forward false
        return

      # backward
      if keySetting.up.pressed(event, pressedKeys):
        window.backward
        return

func setHandlers*(window: AppWindow) {.inline.} =
  ## Sets handlers to the window.
  window.onCloseClick = (event: CloseClickEvent) => event.exitHandler
  window.onKeyDown = (event: KeyboardEvent) => event.keyHandler window.setting[].key

# ------------------------------------------------
# Copy
# ------------------------------------------------

proc copy(window: AppWindow): AppWindow {.inline.} =
  ## Copys the :code:`window`.
  result = window.copyView
  result.setHandlers
