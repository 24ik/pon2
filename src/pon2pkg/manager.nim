## This module implements the manager.
##

import options
import uri
when not defined js:
  import tables

import nazopuyo_core
import puyo_core
import puyo_simulator

when not defined js:
  import ./core/db

when defined js:
  type Manager* = tuple
    ## Nazo Puyo Manager.
    simulator: ref Simulator
    answerSimulator: ref Simulator

    solving: bool
    answers: Option[seq[Positions]]
    answerIdx: Natural

    focusAnswer: bool
else:
  type Manager* = tuple
    ## Nazo Puyo Manager.
    simulator: ref Simulator
    answerSimulator: ref Simulator

    solving: bool
    answers: Option[seq[Positions]]
    answerIdx: Natural

    db: NazoPuyoDatabase

    focusAnswer: bool

# ------------------------------------------------
# Constructor
# ------------------------------------------------

when defined js:
  func toManager*(env: Environment, positions = none Positions, mode = PLAY, showCursor = true): Manager {.inline.} =
    ## Returns the manager.
    result.simulator = new Simulator
    result.simulator[] = env.toSimulator(positions, mode, showCursor)
    result.answerSimulator = new Simulator
    result.answerSimulator[] = makeEmptyNazoPuyo().toSimulator(mode = REPLAY)

    result.solving = false
    result.answers = none seq[Positions]
    result.answerIdx = 0

    result.focusAnswer = false

  func toManager*(nazo: NazoPuyo, positions = none Positions, mode = PLAY, showCursor = true): Manager {.inline.} =
    ## Returns the manager.
    result.simulator = new Simulator
    result.simulator[] = nazo.toSimulator(positions, mode, showCursor)
    result.answerSimulator = new Simulator
    result.answerSimulator[] = makeEmptyNazoPuyo().toSimulator(mode = REPLAY)
    
    result.solving = false
    result.answers = none seq[Positions]
    result.answerIdx = 0

    result.focusAnswer = false
else:
  func toManager*(
    env: Environment, positions = none Positions, mode = PLAY, showCursor = true, db = loadDatabase()
  ): Manager {.inline.} =
    ## Returns the manager.
    result.simulator = new Simulator
    result.simulator[] = env.toSimulator(positions, mode, showCursor)
    result.answerSimulator = new Simulator
    result.answerSimulator[] = makeEmptyNazoPuyo().toSimulator(mode = REPLAY)

    result.solving = false
    result.answers = none seq[Positions]
    result.answerIdx = 0

    result.db = db

    result.focusAnswer = false

  func toManager*(
    nazo: NazoPuyo, positions = none Positions, mode = PLAY, showCursor = true, db = loadDatabase()
  ): Manager {.inline.} =
    ## Returns the manager.
    result.simulator = new Simulator
    result.simulator[] = nazo.toSimulator(positions, mode, showCursor)
    result.answerSimulator = new Simulator
    result.answerSimulator[] = makeEmptyNazoPuyo().toSimulator(mode = REPLAY)
    
    result.solving = false
    result.answers = none seq[Positions]
    result.answerIdx = 0

    result.db = db

    result.focusAnswer = false

# ------------------------------------------------
# Toggle
# ------------------------------------------------

func toggleFocus*(manager: var Manager) {.inline.} =
  ## Toggles `manager.focusAnswer`.
  manager.focusAnswer = not manager.focusAnswer

# ------------------------------------------------
# Solve
# ------------------------------------------------

func updateAnswerSimulator*(manager: var Manager, nazo: NazoPuyo) {.inline.} =
  ## Updates the answer simulator.
  ## This procedure is assumed to be called after `manager.answers` is set.
  assert manager.answers.isSome

  manager.focusAnswer = manager.answers.get.len > 0
  manager.answerSimulator[].environment = nazo.environment
  manager.answerSimulator[].originalEnvironment = nazo.environment
  manager.answerSimulator[].requirement = some nazo.requirement
  if manager.answers.get.len > 0:
    manager.answerSimulator[].positions = manager.answers.get[manager.answerIdx]
  manager.answerIdx = 0

# ------------------------------------------------
# Answer - Prev / Next
# ------------------------------------------------

func nextAnswer*(manager: var Manager) {.inline.} =
  ## Shows the next answer.
  if manager.answers.isNone or manager.answers.get.len == 0:
    return

  if manager.answerIdx == manager.answers.get.len.pred:
    manager.answerIdx = 0
  else:
    manager.answerIdx.inc

  manager.answerSimulator[].positions = manager.answers.get[manager.answerIdx]
  manager.answerSimulator[].reset false

func prevAnswer*(manager: var Manager) {.inline.} =
  ## Shows the previous answer.
  if manager.answers.isNone or manager.answers.get.len == 0:
    return

  if manager.answerIdx == 0:
    manager.answerIdx = manager.answers.get.len.pred
  else:
    manager.answerIdx.dec

  manager.answerSimulator[].positions = manager.answers.get[manager.answerIdx]
  manager.answerSimulator[].reset false

# ------------------------------------------------
# DB
# ------------------------------------------------

when not defined js:
  proc saveToDb*(manager: var Manager) {.inline.} =
    ## Saves the nazo puyo and answers to the database.
    if manager.simulator[].requirement.isNone:
      return

    manager.db.add manager.simulator[].nazoPuyo.get, (if manager.answers.isSome: manager.answers.get else: @[])
    manager.db.saveDatabase

  proc deleteFromDb*(manager: var Manager) {.inline.} =
    ## Deletes the nazo puyo from the database.
    if manager.simulator[].requirement.isNone:
      return

    manager.db.del manager.simulator[].nazoPuyo.get
    manager.db.saveDatabase

# ------------------------------------------------
# Manager -> URI
# ------------------------------------------------

func toUri*(manager: Manager): Uri {.inline.} =
  ## Converts the manager to the URI.
  result = manager.simulator[].toUri
  result.path = "/pon2/playground/index.html"

# ------------------------------------------------
# Keyboard Operation
# ------------------------------------------------

proc operateCommon*(manager: var Manager, event: KeyEvent): bool {.inline.} =
  ## Handler for keyboard input.
  ## Returns `true` if any action is executed.
  ##
  ## NOTE: This procedure does not handle backend-specific operations.
  if event == ("KeyQ", true, false, false, false):
    manager.toggleFocus
    return true

  if manager.focusAnswer:
    # move answer
    if event == ("KeyA", false, false, false, false):
      manager.prevAnswer
      return true
    if event == ("KeyD", false, false, false, false):
      manager.nextAnswer
      return true

    return manager.answerSimulator[].operate event
  else:
    case manager.simulator[].mode
    of IzumiyaSimulatorMode.EDIT:
      # DB
      when not defined js:
        if event == ("KeyR", false, false, false, false):
          manager.saveToDb
          return true
        if event == ("KeyR", true, false, false, false):
          manager.deleteFromDb
          return true
    of PLAY, REPLAY:
      discard

    return manager.simulator[].operate event
