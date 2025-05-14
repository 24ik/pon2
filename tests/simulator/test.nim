{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/[core]
import ../../src/pon2/app/[key, nazopuyowrap, simulator]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

block: # init
  check Simulator.init == Simulator.init NazoPuyoWrap.init

# ------------------------------------------------
# Property
# ------------------------------------------------

block: # nazoPuyoWrap, moveResult, operatingPlacement
  let sim = Simulator.init

  check sim.nazoPuyoWrap == NazoPuyoWrap.init
  check sim.moveResult == MoveResult.init true
  check sim.operatingPlacement == Up2

# ------------------------------------------------
# Placement
# ------------------------------------------------

block:
  # movePlacementRight, movePlacementLeft, rotatePlacementRight, rotatePlacementLeft
  var
    sim = Simulator.init
    plcmt = Up2

  check sim.operatingPlacement == plcmt

  sim.movePlacementRight
  plcmt.moveRight
  check sim.operatingPlacement == plcmt

  sim.movePlacementLeft
  plcmt.moveLeft
  check sim.operatingPlacement == plcmt

  sim.rotatePlacementRight
  plcmt.rotateRight
  check sim.operatingPlacement == plcmt

  sim.rotatePlacementLeft
  plcmt.rotateLeft
  check sim.operatingPlacement == plcmt

# ------------------------------------------------
# Forward / Backward
# ------------------------------------------------

block: # forward, backward
  let
    wrap0 = NazoPuyoWrap.init parseNazoPuyo[TsuField](
      """
3連鎖するべし
======
......
......
......
......
......
......
......
......
......
......
..o.br
.ogbrr
.ggooo
------
rb|"""
    ).unsafeValue
    wrap0P = NazoPuyoWrap.init parseNazoPuyo[TsuField](
      """
3連鎖するべし
======
......
......
......
......
......
......
......
......
......
......
..o.br
.ogbrr
.ggooo
------
rb|6N"""
    ).unsafeValue
    wrap1 = NazoPuyoWrap.init parseNazoPuyo[TsuField](
      """
3連鎖するべし
======
......
......
......
......
......
......
......
......
.....b
.....r
..o.br
.ogbrr
.ggooo
------
rb|6N"""
    ).unsafeValue
    wrap2 = NazoPuyoWrap.init parseNazoPuyo[TsuField](
      """
3連鎖するべし
======
......
......
......
......
......
......
......
......
.....b
......
..o.b.
.ogb..
.ggo..
------
rb|6N"""
    ).unsafeValue
    wrap3 = NazoPuyoWrap.init parseNazoPuyo[TsuField](
      """
3連鎖するべし
======
......
......
......
......
......
......
......
......
......
......
..o...
.ogb..
.ggobb
------
rb|6N"""
    ).unsafeValue

    cnts: array[Cell, int] = [0, 0, 2, 4, 0, 0, 0, 0]
    full: array[Cell, seq[int]] = [@[], @[], @[], @[4], @[], @[], @[], @[]]
    moveRes0 = MoveResult.init true
    moveRes1 = MoveResult.init true
    moveRes2 = MoveResult.init(1, cnts, 0, @[cnts], @[0], @[full])
    moveRes3 = moveRes2

  var sim = Simulator.init wrap0
  check sim.moveResult == moveRes0

  for _ in 1 .. 3:
    sim.movePlacementRight
  sim.forward
  check sim.nazoPuyoWrap == wrap1
  check sim.moveResult == moveRes1

  sim.forward
  check sim.nazoPuyoWrap == wrap2
  check sim.moveResult == moveRes2

  sim.forward
  check sim.nazoPuyoWrap == wrap3
  check sim.moveResult == moveRes3

  sim.forward
  check sim.nazoPuyoWrap == wrap3
  check sim.moveResult == moveRes3

  sim.forward(replay = true)
  check sim.nazoPuyoWrap == wrap3
  check sim.moveResult == moveRes3

  sim.forward(skip = true)
  check sim.nazoPuyoWrap == wrap3
  check sim.moveResult == moveRes3

  sim.backward false
  check sim.nazoPuyoWrap == wrap2
  check sim.moveResult == moveRes2

  sim.backward false
  check sim.nazoPuyoWrap == wrap1
  check sim.moveResult == moveRes1

  sim.backward false
  check sim.nazoPuyoWrap == wrap0P
  check sim.moveResult == moveRes0

  sim.backward false
  check sim.nazoPuyoWrap == wrap0P
  check sim.moveResult == moveRes0

  sim.backward
  check sim.nazoPuyoWrap == wrap0P
  check sim.moveResult == moveRes0

  sim.forward(replay = true)
  check sim.nazoPuyoWrap == wrap1
  check sim.moveResult == moveRes1

  sim.reset
  check sim.nazoPuyoWrap == wrap0P
  check sim.moveResult == moveRes0

  sim.forward(skip = true)
  check sim.nazoPuyoWrap == wrap0
  check sim.moveResult == moveRes0

# ------------------------------------------------
# Keyboard
# ------------------------------------------------

block: # operate
  let nazo = parseNazoPuyo[TsuField](
    """
1連鎖するべし
======
......
......
......
......
......
......
......
......
......
......
......
......
......
------
rg|
by|
pp|"""
  ).expect "Invalid Nazo Puyo"
  var
    sim1 = Simulator.init nazo
    sim2 = Simulator.init nazo
  check sim1 == sim2

  sim1.rotatePlacementLeft
  check sim2.operate KeyEvent.init 'j'
  check sim1 == sim2

  sim1.rotatePlacementRight
  check sim2.operate KeyEvent.init 'k'
  check sim1 == sim2

  sim1.movePlacementLeft
  check sim2.operate KeyEvent.init 'a'
  check sim1 == sim2

  sim1.movePlacementRight
  check sim2.operate KeyEvent.init 'd'
  check sim1 == sim2

  sim1.forward
  check sim2.operate KeyEvent.init 's'
  check sim1 == sim2

  sim1.forward(replay = true)
  check sim2.operate KeyEvent.init '3'
  check sim1 == sim2

  sim1.forward(skip = true)
  check sim2.operate KeyEvent.init "Space"
  check sim1 == sim2

  sim1.backward(toStable = false)
  check sim2.operate KeyEvent.init 'W'
  check sim1 == sim2

  sim1.backward(toStable = false)
  check sim2.operate KeyEvent.init('2', shift = true)
  check sim1 == sim2

  sim1.backward
  check sim2.operate KeyEvent.init 'w'
  check sim1 == sim2

  sim1.backward
  check sim2.operate KeyEvent.init '2'
  check sim1 == sim2

  sim1.reset
  check sim2.operate KeyEvent.init '1'
  check sim1 == sim2

  check not sim2.operate KeyEvent.init 'K'
  check sim1 == sim2

# ------------------------------------------------
# Simulator <-> URI
# ------------------------------------------------

block: # toUri, parseSimulator
  block: # Nazo Puyo
    let
      sim = Simulator.init
      uriPon2 = "https://24ik.github.io/pon2/?field=t_&steps&goal=0_0_".parseUri
      uriIshikawa = "https://ishikawapuyo.net/simu/pn.html?___200".parseUri
      uriIps = "https://ips.karou.jp/simu/pn.html?___200".parseUri

    check sim.toUri(fqdn = Pon2) == Res[Uri].ok uriPon2
    check sim.toUri(fqdn = Ishikawa) == Res[Uri].ok uriIshikawa
    check sim.toUri(fqdn = Ips) == Res[Uri].ok uriIps

    check uriPon2.parseSimulator == Res[Simulator].ok sim
    check uriIshikawa.parseSimulator == Res[Simulator].ok sim
    check uriIps.parseSimulator == Res[Simulator].ok sim

  block: # Puyo Puyo
    let
      sim = Simulator.init PuyoPuyo[TsuField].init
      uriPon2 = "https://24ik.github.io/pon2/?field=t_&steps".parseUri
      uriIshikawa = "https://ishikawapuyo.net/simu/ps.html".parseUri
      uriIps = "https://ips.karou.jp/simu/ps.html".parseUri

    check sim.toUri(fqdn = Pon2) == Res[Uri].ok uriPon2
    check sim.toUri(fqdn = Ishikawa) == Res[Uri].ok uriIshikawa
    check sim.toUri(fqdn = Ips) == Res[Uri].ok uriIps

    check uriPon2.parseSimulator == Res[Simulator].ok sim
    check uriIshikawa.parseSimulator == Res[Simulator].ok sim
    check uriIps.parseSimulator == Res[Simulator].ok sim

  block: # clearPlacements
    let nazo = parseNazoPuyo[TsuField](
      """
6連鎖するべし
======
......
......
......
......
......
......
......
......
......
......
......
......
...b..
------
rb|1N
pp|
gy|23"""
    ).expect "Invalid Nazo Puyo"

    check Simulator.init(nazo).toUri(clearPlacements = true) ==
      Res[Uri].ok "https://24ik.github.io/pon2/?field=t_b..&steps=rbppgy&goal=5__6".parseUri
