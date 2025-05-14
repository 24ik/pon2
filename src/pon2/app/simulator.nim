## This module implements simulators.
##
## Compile Options:
## | Option               | Description                    | Default  |
## | -------------------- | ------------------------------ | -------- |
## | `-d:pon2.path=<str>` | URI path of the web simulator. | `/pon2/` |
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, sugar, uri]
import ./[key, nazopuyowrap]
import ../[core]
import ../private/[assign3, deques2, results2, staticfor2, strutils2]

export deques2, results2, uri

type
  SimulatorState* {.pure.} = enum
    ## Simulator state.
    Settled
    WillPop
    WillSettle

  MoveDequeElem = object
    nazoPuyoWrap: NazoPuyoWrap
    moveResult: MoveResult
    state: SimulatorState

  Simulator* = object ## Puyo Puyo / Nazo Puyo simulator.
    nazoPuyoWrap: NazoPuyoWrap

    moveResult: MoveResult
    state: SimulatorState
    operatingPlacement: Placement
    operatingIdx: int

    moveDeque: Deque[MoveDequeElem]

const Pon2Path* {.define: "pon2.path".} = "/pon2/"

static:
  doAssert Pon2Path.startsWith '/'

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const
  DefaultPlcmt = Up2
  DefaultMoveRes = MoveResult.init true

func init(
    T: type MoveDequeElem,
    wrap: NazoPuyoWrap,
    moveRes: MoveResult,
    state: SimulatorState,
): T {.inline.} =
  T(nazoPuyoWrap: wrap, moveResult: moveRes, state: state)

func init*(T: type Simulator, wrap: NazoPuyoWrap): T {.inline.} =
  T(
    nazoPuyoWrap: wrap,
    moveResult: DefaultMoveRes,
    state: SimulatorState.Settled,
    operatingPlacement: DefaultPlcmt,
    operatingIdx: 0,
    moveDeque: Deque[MoveDequeElem].init,
  )

func init*[F: TsuField or WaterField](
    T: type Simulator, nazo: NazoPuyo[F]
): T {.inline.} =
  T.init NazoPuyoWrap.init nazo

func init*[F: TsuField or WaterField](
    T: type Simulator, puyoPuyo: PuyoPuyo[F]
): T {.inline.} =
  T.init NazoPuyoWrap.init puyoPuyo

func init*(T: type Simulator): T {.inline.} =
  T.init NazoPuyoWrap.init

# ------------------------------------------------
# Property
# ------------------------------------------------

func nazoPuyoWrap*(self: Simulator): NazoPuyoWrap {.inline.} =
  ## Returns the Nazo Puyo wrapper of the simulator.
  self.nazoPuyoWrap

func moveResult*(self: Simulator): MoveResult {.inline.} =
  ## Returns the moving result of the simulator.
  self.moveResult

func operatingPlacement*(self: Simulator): Placement {.inline.} =
  ## Returns the operating placement of the simulator.
  self.operatingPlacement

# ------------------------------------------------
# Placement
# ------------------------------------------------

func movePlacementRight*(self: var Simulator) {.inline.} =
  ## Moves the next placement right.
  self.operatingPlacement.moveRight

func movePlacementLeft*(self: var Simulator) {.inline.} =
  ## Moves the next placement left.
  self.operatingPlacement.moveLeft

func rotatePlacementRight*(self: var Simulator) {.inline.} =
  ## Rotates the next placement right (clockwise).
  self.operatingPlacement.rotateRight

func rotatePlacementLeft*(self: var Simulator) {.inline.} =
  ## Rotates the next placement left (counterclockwise).
  self.operatingPlacement.rotateLeft

# ------------------------------------------------
# Forward / Backward
# ------------------------------------------------

func save(self: var Simulator) {.inline.} =
  ## Saves the current simulator to the undo deque.
  self.moveDeque.addLast MoveDequeElem.init(
    self.nazoPuyoWrap, self.moveResult, self.state
  )

func load(self: var Simulator) {.inline.} =
  ## Loads the last saved simulator.
  let elem = self.moveDeque.popLast

  self.nazoPuyoWrap.assign elem.nazoPuyoWrap
  self.moveResult.assign elem.moveResult
  self.state.assign elem.state

func forward*(self: var Simulator, replay = false, skip = false) {.inline.} =
  ## Forwards the simulator.
  ## This functions requires that the initial field is settled.
  ## `skip` is prioritized over `replay`.
  self.nazoPuyoWrap.runIt:
    case self.state
    of Settled:
      if self.operatingIdx >= it.steps.len:
        return

      self.save

      self.moveResult.assign DefaultMoveRes

      # set placement
      if it.steps[self.operatingIdx].kind != PairPlacement:
        discard
      elif skip:
        it.steps[self.operatingIdx].optPlacement.err
      elif replay:
        discard
      else:
        it.steps[self.operatingIdx].optPlacement.ok self.operatingPlacement

      it.field.apply it.steps[self.operatingIdx]

      # check pop
      if it.field.canPop:
        self.state.assign WillPop
      else:
        self.state.assign Settled
        self.operatingIdx.inc
        self.operatingPlacement.assign DefaultPlcmt
    of WillPop:
      self.save

      let popRes = it.field.pop

      # update moving result
      self.moveResult.chainCnt.inc
      var cellCnts {.noinit.}: array[Cell, int]
      cellCnts[None].assign 0
      staticFor(cell2, Hard .. Cell.Purple):
        let cellCnt = popRes.cellCnt cell2
        cellCnts[cell2].assign cellCnt
        self.moveResult.popCnts[cell2].inc cellCnt
      self.moveResult.detailPopCnts.add cellCnts
      self.moveResult.fullPopCnts.unsafeValue.add popRes.connCnts
      let h2g = popRes.hardToGarbageCnt
      self.moveResult.hardToGarbageCnt.inc h2g
      self.moveResult.detailHardToGarbageCnt.add h2g

      # check settle
      if it.field.isSettled:
        self.state.assign Settled
        self.operatingIdx.inc
        self.operatingPlacement.assign DefaultPlcmt
      else:
        self.state.assign WillSettle
    of WillSettle:
      self.save

      # check pop
      it.field.settle
      if it.field.canPop:
        self.state.assign WillPop
      else:
        self.state.assign Settled
        self.operatingIdx.inc
        self.operatingPlacement.assign DefaultPlcmt

func backward*(self: var Simulator, toStable = true) {.inline.} =
  ## Backwards the simulator.
  if self.moveDeque.len == 0:
    return

  # save the steps to keep the placements
  let steps = self.nazoPuyoWrap.runIt:
    it.steps

  if self.state == Settled:
    self.operatingIdx.dec

  if toStable:
    while self.moveDeque.peekLast.state != Settled:
      self.moveDeque.popLast

  self.load

  self.nazoPuyoWrap.runIt:
    it.steps.assign steps
  self.operatingPlacement.assign DefaultPlcmt

func reset*(self: var Simulator) {.inline.} =
  ## Backwards the simulator to the initial one.
  if self.moveDeque.len == 0:
    return

  # save the steps to keep the placements
  let steps = self.nazoPuyoWrap.runIt:
    it.steps

  self.nazoPuyoWrap.assign self.moveDeque.peekFirst.nazoPuyoWrap
  self.nazoPuyoWrap.runIt:
    it.steps.assign steps
  self.moveResult.assign self.moveDeque.peekFirst.moveResult
  self.state.assign Settled
  self.operatingPlacement.assign DefaultPlcmt
  self.operatingIdx.assign 0
  self.moveDeque.clear

# ------------------------------------------------
# Keyboard
# ------------------------------------------------

func operate*(self: var Simulator, key: KeyEvent): bool {.inline, discardable.} =
  ## Performs an action specified by the key.
  ## Returns `true` if any action is performed.
  var acted = true

  # rotate plcmt
  if key == static(KeyEvent.init 'j'):
    self.rotatePlacementLeft
  elif key == static(KeyEvent.init 'k'):
    self.rotatePlacementRight
  # move plcmt
  elif key == static(KeyEvent.init 'a'):
    self.movePlacementLeft
  elif key == static(KeyEvent.init 'd'):
    self.movePlacementRight
  # forward / backward / reset
  elif key == static(KeyEvent.init 's'):
    self.forward
  elif key in static([KeyEvent.init '2', KeyEvent.init 'w']):
    self.backward
  elif key in static([KeyEvent.init('2', shift = true), KeyEvent.init 'W']):
    self.backward(toStable = false)
  elif key == static(KeyEvent.init '1'):
    self.reset
  elif key == static(KeyEvent.init "Space"):
    self.forward(skip = true)
  elif key == static(KeyEvent.init '3'):
    self.forward(replay = true)
  else:
    acted.assign false

  acted

# ------------------------------------------------
# Simulator <-> URI
# ------------------------------------------------

func initPon2Paths(): seq[string] {.inline.} =
  ## Returns `Pon2Paths`.
  if Pon2Path.endsWith '/':
    @[Pon2Path, "{Pon2Path}index.html".fmt]
  elif Pon2Path.endsWith "/index.html":
    @[Pon2Path, Pon2Path.dup(removeSuffix(_, "index.html"))]
  else:
    @[Pon2Path]

const Pon2Paths = initPon2Paths()

func toUri*(
    self: Simulator, clearPlacements = false, fqdn = Pon2
): Res[Uri] {.inline.} =
  ## Returns the URI converted from the simulator.
  var simUri = initUri()
  simUri.scheme.assign "https"
  simUri.hostname.assign $fqdn
  simUri.path.assign(
    case fqdn
    of Pon2:
      Pon2Path
    of Ishikawa, Ips:
      if self.nazoPuyoWrap.optGoal.isOk: "/simu/pn.html" else: "/simu/ps.html"
  )

  var wrap = self.nazoPuyoWrap
  if clearPlacements:
    wrap.runIt:
      for step in it.steps.mitems:
        if step.kind == PairPlacement:
          step.optPlacement.err

  simUri.query.assign ?wrap.toUriQuery(fqdn).context "Invalid simulator"

  ok simUri

func parseSimulator*(uri: Uri): Res[Simulator] {.inline.} =
  ## Returns the simulator converted from the URI.
  let fqdn: SimulatorFqdn
  case uri.hostname
  of $Pon2:
    fqdn = Pon2

    if uri.scheme != "https":
      return err "Invalid simulator (invalid scheme): {uri}".fmt
    if uri.path notin Pon2Paths:
      return err "Invalid simulator (invalid path): {uri}".fmt
  of $Ishikawa, $Ips:
    fqdn = if uri.hostname == $Ishikawa: Ishikawa else: Ips

    if uri.scheme notin ["https", "http"]:
      return err "Invalid simulator (invalid scheme): {uri}".fmt
    if uri.path notin
        ["/simu/pe.html", "/simu/ps.html", "/simu/pv.html", "/simu/pn.html"]:
      return err "Invalid simulator (invalid path): {uri}".fmt
  else:
    fqdn = SimulatorFqdn.low # NOTE: dummy to compile
    return err "Invalid simulator (invalid FQDN): {uri}".fmt

  ok Simulator.init ?uri.query.parseNazoPuyoWrap(fqdn).context "Invalid simulator: {uri}".fmt
