{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, unittest, uri]
import ../../src/pon2pkg/corepkg/[pair, position]
import ../../src/pon2pkg/nazopuyopkg/[nazopuyo, solve]

proc checkSolve(questionUri: string, answersStrs: varargs[string]) =
  let answers = answersStrs.mapIt it.parsePositions
  questionUri.parseUri.parseNazoPuyos.nazoPuyos.flattenAnd:
    check nazoPuyo.solve == answers

proc main* =
  # ------------------------------------------------
  # Solve
  # ------------------------------------------------

  # solve
  block:
    # Clear
    checkSolve "https://ishikawapuyo.net/simu/pn.html?r4AA3r_E1E1__200", "43\n3F"
    checkSolve "https://ishikawapuyo.net/simu/pn.html?w00908e08y08ANwO9wOmSSSSSSSSSSSSSSSS_0101__210", "3N\n34"
    checkSolve "https://ishikawapuyo.net/simu/pn.html?1kP1kP1kP3Ny3Ny3Ny2Cp2Cp2Cp_o1i1__260", "56\n6F"
    checkSolve "https://ishikawapuyo.net/simu/pn.html?800F08J08A0EB_8161__270", "45\n4N"

    # DisappearColor
    checkSolve "https://ishikawapuyo.net/simu/pn.html?2p3j9_g1c1__a03", "3F\n65"

    # DisappearColorMore
    checkSolve "https://ishikawapuyo.net/simu/pn.html?uo9cA_41E1__b03",
        "4F\n56", "4F\n6F"

    # DisappearCount
    checkSolve "https://ishikawapuyo.net/simu/pn.html?o00w0ig0SM0SPr_G1i1__c0i",
        "1N\n2F", "12\n4N"

    # DisappearCountMore
    checkSolve "https://ishikawapuyo.net/simu/pn.html?1Oo1bo3hg3p81bM2bo_o1o1__d0s", "1N\n1F"

    # Chain
    checkSolve "https://ishikawapuyo.net/simu/pn.html?1081681S84CM_A1A1__u03", "4F\n3N"

    # ChainMore
    checkSolve "https://ishikawapuyo.net/simu/pn.html?Mp6j92mS_o1q1__v03", "43\n12"

    # ChainClear
    checkSolve "https://ishikawapuyo.net/simu/pn.html?3w03s01c0Sr0SbS_o1u1__w04", "1F\n5F"

    # ChainMoreClear
    checkSolve "https://ishikawapuyo.net/simu/pn.html?200i0iJiGGGJiJ_k1k1__x04", "3N\n56"

    # DisappearColorSametime
    checkSolve "https://ishikawapuyo.net/simu/pn.html?2005M05g05g06g65E2iE_O1O1__E02", "65\n6F"

    # DisappearColorMoreSametime
    checkSolve "https://ishikawapuyo.net/simu/pn.html?600300200100p00pg_q1c1__E02", "65\n56"

    # DisappearCountSametime
    checkSolve "https://ishikawapuyo.net/simu/pn.html?10090aj09jo_o1c1__G0c", "3F\n32"
    checkSolve "https://ishikawapuyo.net/simu/pn.html?11011M16Me69S6Nc4CA4Ne6N96N_G161__G0o", "3N\n34"

    # DisappearCountMoreSametime
    checkSolve "https://ishikawapuyo.net/simu/pn.html?pp9b9rpr_o1o1o1__H0b",
        "34\n3N\n23", "34\n34\n23"

    # DisappearPlace
    checkSolve "https://ishikawapuyo.net/simu/pn.html?8w0wAcw_A1A1__I02", "4F\n32"

    # DisappearPlaceMore
    checkSolve "https://ishikawapuyo.net/simu/pn.html?8w0wAcw_A1A1__J02", "4F\n32"

    # DisappearConnect
    checkSolve "https://ishikawapuyo.net/simu/pn.html?M0hh0ia09r0ij8_e1g1__Q07", "4N\n54"

    # DisappearConnectMore
    checkSolve "https://ishikawapuyo.net/simu/pn.html?M0hh0ia09r0ij8_e1g1__R07", "4N\n54"
