import options
import sequtils
import std/sets
import strutils
import unittest

import puyo_core

import ../../src/pon2pkg/core/solve {.all.}

func toIps(url: string): string = url.replace("https://ishikawapuyo.net", "http://ips.karou.jp")

proc checkSolveCore(question: string, answers: openArray[string]) =
  check question.solve(ISHIKAWAPUYO).get.toHashSet == answers.toHashSet
  check question.solve(IPS).get.toHashSet == answers.mapIt(it.toIps).toHashSet

  block:
    let solutions = question.inspect_solve(false, ISHIKAWAPUYO).get
    check solutions[0].toHashSet == answers.toHashSet
  block:
    let solutions = question.inspect_solve(false, IPS).get
    check solutions[0].toHashSet == answers.mapIt(it.toIps).toHashSet

proc checkSolve(question: string, answers: openArray[string]) =
  question.checkSolveCore answers
  question.toIps.checkSolveCore answers

proc main* =
  # CLEAR
  checkSolve "https://ishikawapuyo.net/simu/pn.html?r4AA3r_E1E1__200",
    ["https://ishikawapuyo.net/simu/pn.html?r4AA3r_EGEs__200"]
  checkSolve "https://ishikawapuyo.net/simu/pn.html?w00908e08y08ANwO9wOmSSSSSSSSSSSSSSSS_0101__210",
    ["https://ishikawapuyo.net/simu/pn.html?w00908e08y08ANwO9wOmSSSSSSSSSSSSSSSS_040g__210"]
  checkSolve "https://ishikawapuyo.net/simu/pn.html?1kP1kP1kP3Ny3Ny3Ny2Cp2Cp2Cp_o1i1__260",
    ["https://ishikawapuyo.net/simu/pn.html?1kP1kP1kP3Ny3Ny3Ny2Cp2Cp2Cp_okiy__260"]
  checkSolve "https://ishikawapuyo.net/simu/pn.html?800F08J08A0EB_8161__270",
    ["https://ishikawapuyo.net/simu/pn.html?800F08J08A0EB_8i66__270"]

  # DISAPPEAR_COLOR
  checkSolve "https://ishikawapuyo.net/simu/pn.html?2p3j9_g1c1__a03",
    ["https://ishikawapuyo.net/simu/pn.html?2p3j9_gscK__a03"]

  # DISAPPEAR_COLOR_MORE
  checkSolve "https://ishikawapuyo.net/simu/pn.html?uo9cA_41E1__b03",
    [
      "https://ishikawapuyo.net/simu/pn.html?uo9cA_4uEy__b03",
      "https://ishikawapuyo.net/simu/pn.html?uo9cA_4uEk__b03"
    ]

  # DISAPPEAR_NUM
  checkSolve "https://ishikawapuyo.net/simu/pn.html?o00w0ig0SM0SPr_G1i1__c0i",
    [
      "https://ishikawapuyo.net/simu/pn.html?o00w0ig0SM0SPr_G0iq__c0i",
      "https://ishikawapuyo.net/simu/pn.html?o00w0ig0SM0SPr_Gci6__c0i"
    ]

  # DISAPPEAR_NUM_MORE
  checkSolve "https://ishikawapuyo.net/simu/pn.html?1Oo1bo3hg3p81bM2bo_o1o1__d0s",
    ["https://ishikawapuyo.net/simu/pn.html?1Oo1bo3hg3p81bM2bo_o0oo__d0s"]

  # CHAIN
  checkSolve "https://ishikawapuyo.net/simu/pn.html?1081681S84CM_A1A1__u03",
    ["https://ishikawapuyo.net/simu/pn.html?1081681S84CM_AuA4__u03"]

  # CHAIN_MORE
  checkSolve "https://ishikawapuyo.net/simu/pn.html?Mp6j92mS_o1q1__v03",
    ["https://ishikawapuyo.net/simu/pn.html?Mp6j92mS_oGqc__v03"]

  # CHAIN_CLEAR
  checkSolve "https://ishikawapuyo.net/simu/pn.html?3w03s01c0Sr0SbS_o1u1__w04",
    ["https://ishikawapuyo.net/simu/pn.html?3w03s01c0Sr0SbS_oouw__w04"]

  # CHAIN_MORE_CLEAR
  checkSolve "https://ishikawapuyo.net/simu/pn.html?200i0iJiGGGJiJ_k1k1__x04",
    ["https://ishikawapuyo.net/simu/pn.html?200i0iJiGGGJiJ_k4kk__x04"]

  # DISAPPEAR_COLOR_SAMETIME
  checkSolve "https://ishikawapuyo.net/simu/pn.html?2005M05g05g06g65E2iE_O1O1__E02",
    ["https://ishikawapuyo.net/simu/pn.html?2005M05g05g06g65E2iE_OKOy__E02"]

  # DISAPPEAR_COLOR_MORE_SAMETIME
  checkSolve "https://ishikawapuyo.net/simu/pn.html?600300200100p00pg_q1c1__E02",
    ["https://ishikawapuyo.net/simu/pn.html?600300200100p00pg_qKck__E02"]

  # DISAPPEAR_NUM_SAMETIME
  checkSolve "https://ishikawapuyo.net/simu/pn.html?10090aj09jo_o1c1__G0c",
    ["https://ishikawapuyo.net/simu/pn.html?10090aj09jo_oscE__G0c"]
  checkSolve "https://ishikawapuyo.net/simu/pn.html?11011M16Me69S6Nc4CA4Ne6N96N_G161__G0o",
    ["https://ishikawapuyo.net/simu/pn.html?11011M16Me69S6Nc4CA4Ne6N96N_G46g__G0o"]

  # DISAPPEAR_NUM_MORE_SAMETIME
  checkSolve "https://ishikawapuyo.net/simu/pn.html?pp9b9rpr_o1o1o1__H0b",
    [
      "https://ishikawapuyo.net/simu/pn.html?pp9b9rpr_ogogoe__H0b",
      "https://ishikawapuyo.net/simu/pn.html?pp9b9rpr_ogo4oe__H0b",
    ]

  # DISAPPEAR_PLACE
  checkSolve "https://ishikawapuyo.net/simu/pn.html?8w0wAcw_A1A1__I02",
    ["https://ishikawapuyo.net/simu/pn.html?8w0wAcw_AuAE__I02"]

  # DISAPPEAR_PLACE_MORE
  checkSolve "https://ishikawapuyo.net/simu/pn.html?8w0wAcw_A1A1__J02",
    ["https://ishikawapuyo.net/simu/pn.html?8w0wAcw_AuAE__J02"]

  # DISAPPEAR_CONNECT
  checkSolve "https://ishikawapuyo.net/simu/pn.html?M0hh0ia09r0ij8_e1g1__Q07",
    ["https://ishikawapuyo.net/simu/pn.html?M0hh0ia09r0ij8_e6gI__Q07"]

  # DISAPPEAR_CONNECT_MORE
  checkSolve "https://ishikawapuyo.net/simu/pn.html?M0hh0ia09r0ij8_e1g1__R07",
    ["https://ishikawapuyo.net/simu/pn.html?M0hh0ia09r0ij8_e6gI__R07"]
