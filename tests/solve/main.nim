{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, sets, sugar, unittest, uri]
import ../../src/pon2/app/[solve]
import ../../src/pon2/core/[field, fqdn, nazopuyo, pairposition, position, puyopuyo]

proc checkSolve(question: string, answers: varargs[string]) =
  let
    nazo = parseNazoPuyo[TsuField](question, Ishikawa)
    answersSeq = collect:
      for answer in answers:
        (0 ..< answer.len div 2).toSeq.mapIt(
          PairPosition(
            pair: nazo.puyoPuyo.pairsPositions[it].pair,
            position: answer[2 * it ..< 2 * it.succ].parsePosition,
          )
        )
    answersSet = answersSeq.toHashSet

  check nazo.solve.toHashSet == answersSet

proc main*() =
  # ------------------------------------------------
  # Solve
  # ------------------------------------------------

  # solve
  block:
    # Clear
    checkSolve "r4AA3r_E1E1__200", "433F"
    checkSolve "w00908e08y08ANwO9wOmSSSSSSSSSSSSSSSS_0101__210", "3N34"
    checkSolve "1kP1kP1kP3Ny3Ny3Ny2Cp2Cp2Cp_o1i1__260", "566F"
    checkSolve "800F08J08A0EB_8161__270", "454N"

    # DisappearColor
    checkSolve "2p3j9_g1c1__a03", "3F65"

    # DisappearColorMore
    checkSolve "uo9cA_41E1__b03", "4F56", "4F6F"

    # DisappearCount
    checkSolve "o00w0ig0SM0SPr_G1i1__c0i", "1N2F", "124N"

    # DisappearCountMore
    checkSolve "1Oo1bo3hg3p81bM2bo_o1o1__d0s", "1N1F"

    # Chain
    checkSolve "1081681S84CM_A1A1__u03", "4F3N"

    # ChainMore
    checkSolve "Mp6j92mS_o1q1__v03", "4312"

    # ChainClear
    checkSolve "3w03s01c0Sr0SbS_o1u1__w04", "1F5F"

    # ChainMoreClear
    checkSolve "200i0iJiGGGJiJ_k1k1__x04", "3N56"

    # DisappearColorSametime
    checkSolve "2005M05g05g06g65E2iE_O1O1__E02", "656F"

    # DisappearColorMoreSametime
    checkSolve "600300200100p00pg_q1c1__E02", "6556"

    # DisappearCountSametime
    checkSolve "10090aj09jo_o1c1__G0c", "3F32"
    checkSolve "11011M16Me69S6Nc4CA4Ne6N96N_G161__G0o", "3N34"

    # DisappearCountMoreSametime
    checkSolve "pp9b9rpr_o1o1o1__H0b", "343N23", "343423"

    # DisappearPlace
    checkSolve "8w0wAcw_A1A1__I02", "4F32"

    # DisappearPlaceMore
    checkSolve "8w0wAcw_A1A1__J02", "4F32"

    # DisappearConnect
    checkSolve "M0hh0ia09r0ij8_e1g1__Q07", "4N54"

    # DisappearConnectMore
    checkSolve "M0hh0ia09r0ij8_e1g1__R07", "4N54"
