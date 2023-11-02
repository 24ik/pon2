{.experimental: "strictDefs".}

import std/[options, unittest, uri]
import ../../src/pon2pkg/core/[position]
import ../../src/pon2pkg/core/nazo/[mark {.all.}, nazoPuyo]

func mark(uriStr: string): MarkResult =
  let parseRes = uriStr.parseUri.parseNazoPuyos
  parseRes.nazoPuyos.flatten:
    result = nazoPuyo.mark parseRes.positions.get

func mark(uriStr: string, positions: Positions): MarkResult =
  uriStr.parseUri.parseNazoPuyos.nazoPuyos.flatten:
    result = nazoPuyo.mark positions

proc main* =
  # ------------------------------------------------
  # Mark
  # ------------------------------------------------

  # Clear
  block:
    check "https://ishikawapuyo.net/simu/pn.html?r4AA3r_EGEs__200".mark ==
      Accept
    check "https://ishikawapuyo.net/simu/pn.html?r4AA3r_EGEs__200".mark(
      @[some Left3, some Down2]) == Accept
    check "https://ishikawapuyo.net/simu/pn.html?r4AA3r_EGE0__200".mark ==
      WrongAnswer
    check "https://ishikawapuyo.net/simu/pn.html?r4AA3r_EGE1__200".mark ==
      WrongAnswer
    check "https://ishikawapuyo.net/simu/pn.html?r4AA3r_E1Es__200".mark ==
      SkipMove

  # DisappearColor
  block:
    check "https://ishikawapuyo.net/simu/pn.html?2p3j9_gscK__a03".mark ==
      Accept
    check "https://ishikawapuyo.net/simu/pn.html?2p3j9_gGcK__a03".mark ==
      WrongAnswer

  # DisappearColorMore
  block:
    check "https://ishikawapuyo.net/simu/pn.html?uo9cA_4uEy__b03".mark == Accept
    check "https://ishikawapuyo.net/simu/pn.html?uo9cA_4EEy__b03".mark ==
      WrongAnswer

  # DisappearCount
  block:
    check "https://ishikawapuyo.net/simu/pn.html?o00w0ig0SM0SPr_G0iq__c0i".
      mark == Accept
    check "https://ishikawapuyo.net/simu/pn.html?o00w0ig0SM0SPr_Giiu__c0i".
      mark == WrongAnswer

  # DisappearCountMore
  block:
    check "https://ishikawapuyo.net/simu/pn.html?1Oo1bo3hg3p81bM2bo_o0oo__d0s".
      mark == Accept
    check "https://ishikawapuyo.net/simu/pn.html?1Oo1bo3hg3p81bM2bo_o0o0__d0s".
      mark == WrongAnswer

  # Chain
  block:
    check "https://ishikawapuyo.net/simu/pn.html?1081681S84CM_AuA4__u03".mark ==
      Accept
    check "https://ishikawapuyo.net/simu/pn.html?1081681S84CM_AuAE__u03".mark ==
      WrongAnswer
    check mark("https://ishikawapuyo.net" &
               "/simu/pn.html?800800800o00900p00r00c00A00a009g0_ec6c__u05") ==
      ImpossibleMove
    check "https://ishikawapuyo.net/simu/pn.html?900A00k00h00c01cw_24C464__u05".
      mark == Dead

  # ChainMore
  block:
    check "https://ishikawapuyo.net/simu/pn.html?Mp6j92mS_oGqc__v03".mark ==
      Accept
    check "https://ishikawapuyo.net/simu/pn.html?Mp6j92mS_ouqi__v03".mark ==
      WrongAnswer

  # ChainClear
  block:
    check "https://ishikawapuyo.net/simu/pn.html?3w03s01c0Sr0SbS_oouw__w04".
      mark == Accept
    check "https://ishikawapuyo.net/simu/pn.html?3w03s01c0Sr0SbS_ouuE__w04".
      mark == WrongAnswer

  # ChainMoreClear
  block:
    check "https://ishikawapuyo.net/simu/pn.html?200i0iJiGGGJiJ_k4kk__x04".
      mark == Accept
    check "https://ishikawapuyo.net/simu/pn.html?200i0iJiGGGJiJ_k6kC__x04".
      mark == WrongAnswer

  # DisappearColorSametime
  block:
    check mark(
      "https://ishikawapuyo.net/simu/pn.html?2005M05g05g06g65E2iE_OKOy__E02"
    ) == Accept
    check mark(
      "https://ishikawapuyo.net/simu/pn.html?2005M05g05g06g65E2iE_OyO8__E02"
    ) == WrongAnswer

  # DisappearColorMoreSametime
  block:
    check "https://ishikawapuyo.net/simu/pn.html?600300200100p00pg_qKck__E02".
      mark == Accept
    check "https://ishikawapuyo.net/simu/pn.html?600300200100p00pg_qKcI__E02".
      mark == WrongAnswer

  # DisappearCountSametime
  block:
    check "https://ishikawapuyo.net/simu/pn.html?10090aj09jo_oscE__G0c".mark ==
      Accept
    check "https://ishikawapuyo.net/simu/pn.html?10090aj09jo_oscq__G0c".mark ==
      WrongAnswer
    check mark(
      "https://ishikawapuyo.net/simu/pn.html?11011M16Me69S6Nc4CA4Ne6N96N_G46g__G0o"
    ) == Accept
    check mark(
      "https://ishikawapuyo.net/simu/pn.html?11011M16Me69S6Nc4CA4Ne6N96N_G464__G0o"
    ) == WrongAnswer

  # DisappearCountMoreSametime
  block:
    check "https://ishikawapuyo.net/simu/pn.html?pp9b9rpr_ogogoe__H0b".mark ==
      Accept
    check "https://ishikawapuyo.net/simu/pn.html?pp9b9rpr_osouow__H0b".mark ==
      WrongAnswer

  # DisappearPlace
  block:
    check "https://ishikawapuyo.net/simu/pn.html?8w0wAcw_AuAE__I02".mark ==
      Accept
    check "https://ishikawapuyo.net/simu/pn.html?8w0wAcw_A4Au__I02".mark ==
      WrongAnswer

  # DisappearPlaceMore
  block:
    check "https://ishikawapuyo.net/simu/pn.html?8w0wAcw_AuAE__J02".mark ==
      Accept
    check "https://ishikawapuyo.net/simu/pn.html?8w0wAcw_A4Au__J02".mark ==
      WrongAnswer

  # DisappearConnect
  block:
    check "https://ishikawapuyo.net/simu/pn.html?M0hh0ia09r0ij8_e6gI__Q07".
      mark == Accept
    check "https://ishikawapuyo.net/simu/pn.html?M0hh0ia09r0ij8_e2gC__Q07".
      mark == WrongAnswer

  # DisappearConnectMore
  block:
    check "https://ishikawapuyo.net/simu/pn.html?M0hh0ia09r0ij8_e6gI__R07".
      mark == Accept
    check "https://ishikawapuyo.net/simu/pn.html?M0hh0ia09r0ij8_e2gC__R07".
      mark == WrongAnswer
