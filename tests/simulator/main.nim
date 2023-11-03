{.experimental: "strictDefs".}

import std/[options, unittest, uri]
import ../../src/pon2pkg/core/[environment, pair, position] # somehow needed
import ../../src/pon2pkg/core/nazoPuyo/[nazoPuyo]
import ../../src/pon2pkg/simulator/[simulator {.all.}]

proc main* =
  # ------------------------------------------------
  # Property
  # ------------------------------------------------

  # nazoPuyo, originalNazoPuyo
  block:
    let nazo = "https://ishikawapuyo.net/simu/pn.html?3ww3so4zM_s1G1u1__u04".
      parseUri.parseTsuNazoPuyo.nazoPuyo
    var simulator = nazo.initSimulator
    check simulator.tsuNazoPuyo == nazo
    check simulator.originalTsuNazoPuyo == nazo

    simulator.nextPosition = Down5
    simulator.forward
    while simulator.state != Stable:
      simulator.forward
    check simulator.tsuNazoPuyo ==
      "https://ishikawapuyo.net/simu/pn.html?3ww3sr4zP_G1u1__u04".
      parseUri.parseTsuNazoPuyo.nazoPuyo
    check simulator.originalTsuNazoPuyo == nazo

  # ------------------------------------------------
  # Forward / Backward
  # ------------------------------------------------

  # forward
  block:
    var simulator = "https://ishikawapuyo.net/simu/pn.html?Mp6j92mS_o1q1__u03".
      parseUri.parseTsuNazoPuyo.nazoPuyo.initSimulator

    simulator.nextPosition = Up5
    simulator.forward
    check simulator.state == WillDisappear
    check simulator.tsuNazoPuyo ==
      "https://ishikawapuyo.net/simu/pn.html?30010Mp6j92mS_q1__u03".
      parseUri.parseTsuNazoPuyo.nazoPuyo
    check simulator.positions == @[some Up5, none Position]
    check simulator.nextIdx == 0

    simulator.forward
    check simulator.state == Disappearing
    check simulator.tsuNazoPuyo ==
      "https://ishikawapuyo.net/simu/pn.html?30000Mo6j02m0_q1__u03".
      parseUri.parseTsuNazoPuyo.nazoPuyo
    check simulator.positions == @[some Up5, none Position]
    check simulator.nextIdx == 0

    simulator.forward
    check simulator.state == Stable
    check simulator.tsuNazoPuyo ==
      "https://ishikawapuyo.net/simu/pn.html?M06j02mr_q1__u03".
      parseUri.parseTsuNazoPuyo.nazoPuyo
    check simulator.positions == @[some Up5, none Position]
    check simulator.nextIdx == 1

  # forward w/ arguments
  block:
    block:
      var simulator =
        "https://ishikawapuyo.net/simu/pn.html?Mp6j92mS_o1q1__u03".
        parseUri.parseTsuNazoPuyo.nazoPuyo.initSimulator
      simulator.positions = @[some Up5, none Position]
      simulator.forward(useNextPosition = false)
      check simulator.tsuNazoPuyo ==
        "https://ishikawapuyo.net/simu/pn.html?30010Mp6j92mS_q1__u03".
        parseUri.parseTsuNazoPuyo.nazoPuyo

    block:
      var simulator =
        "https://ishikawapuyo.net/simu/pn.html?Mp6j92mS_o1q1__u03".
        parseUri.parseTsuNazoPuyo.nazoPuyo.initSimulator
      simulator.forward(skip = true)
      check simulator.tsuNazoPuyo ==
        "https://ishikawapuyo.net/simu/pn.html?Mp6j92mS_q1__u03".
        parseUri.parseTsuNazoPuyo.nazoPuyo

  # backward, reset
  block:
    let nazo = "https://ishikawapuyo.net/simu/pn.html?Mp6j92mS_o1q1__u03".
      parseUri.parseTsuNazoPuyo.nazoPuyo
    var simulator = nazo.initSimulator

    simulator.nextPosition = Up5
    simulator.forward
    simulator.backward
    check simulator.tsuNazoPuyo == nazo
    check simulator.state == Stable
    check simulator.positions == @[some Up5, none Position]
    check simulator.nextIdx == 0

    simulator.nextPosition = Up5
    simulator.forward
    simulator.forward
    simulator.backward
    check simulator.tsuNazoPuyo == nazo
    check simulator.state == Stable
    check simulator.positions == @[some Up5, none Position]
    check simulator.nextIdx == 0

    simulator.nextPosition = Up5
    simulator.forward
    simulator.forward
    simulator.forward
    simulator.backward
    check simulator.tsuNazoPuyo == nazo
    check simulator.state == Stable
    check simulator.positions == @[some Up5, none Position]
    check simulator.nextIdx == 0

    simulator.nextPosition = Up5
    simulator.forward
    simulator.forward
    simulator.forward
    simulator.nextPosition = Right0
    simulator.forward
    simulator.backward
    check simulator.tsuNazoPuyo ==
      "https://ishikawapuyo.net/simu/pn.html?M06j02mr_q1__u03".
      parseUri.parseTsuNazoPuyo.nazoPuyo
    check simulator.state == Stable
    check simulator.positions == @[some Up5, some Right0]
    check simulator.nextIdx == 1

    simulator.reset false
    check simulator.tsuNazoPuyo == nazo
    check simulator.state == Stable
    check simulator.positions == @[some Up5, some Right0]
    check simulator.nextIdx == 0

    simulator.reset
    check simulator.tsuNazoPuyo == nazo
    check simulator.state == Stable
    check simulator.positions == newSeq[Option[Position]] nazo.moveCount
    check simulator.nextIdx == 0
