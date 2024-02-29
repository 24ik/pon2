{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2pkg/core/[field, host, mark {.all.}, nazopuyo]

func mark(uriStr: string): MarkResult =
  parseNazoPuyo[TsuField](uriStr, Ishikawa).mark

proc main*() =
  # ------------------------------------------------
  # Mark
  # ------------------------------------------------
  # Clear
  block:
    check "r4AA3r_EGEs__200".mark == Accept
    check "r4AA3r_EGE0__200".mark == WrongAnswer
    check "r4AA3r_EGE1__200".mark == WrongAnswer
    check "r4AA3r_E1Es__200".mark == SkipMove

  # DisappearColor
  block:
    check "2p3j9_gscK__a03".mark == Accept
    check "2p3j9_gGcK__a03".mark == WrongAnswer

  # DisappearColorMore
  block:
    check "uo9cA_4uEy__b03".mark == Accept
    check "uo9cA_4EEy__b03".mark == WrongAnswer

  # DisappearCount
  block:
    check "o00w0ig0SM0SPr_G0iq__c0i".mark == Accept
    check "o00w0ig0SM0SPr_Giiu__c0i".mark == WrongAnswer

  # DisappearCountMore
  block:
    check "1Oo1bo3hg3p81bM2bo_o0oo__d0s".mark == Accept
    check "1Oo1bo3hg3p81bM2bo_o0o0__d0s".mark == WrongAnswer

  # Chain
  block:
    check "1081681S84CM_AuA4__u03".mark == Accept
    check "1081681S84CM_AuAE__u03".mark == WrongAnswer
    check "800800800o00900p00r00c00A00a009g0_ec6c__u05".mark == ImpossibleMove
    check "900A00k00h00c01cw_24C464__u05".mark == Dead

  # ChainMore
  block:
    check "Mp6j92mS_oGqc__v03".mark == Accept
    check "Mp6j92mS_ouqi__v03".mark == WrongAnswer

  # ChainClear
  block:
    check "3w03s01c0Sr0SbS_oouw__w04".mark == Accept
    check "3w03s01c0Sr0SbS_ouuE__w04".mark == WrongAnswer

  # ChainMoreClear
  block:
    check "200i0iJiGGGJiJ_k4kk__x04".mark == Accept
    check "200i0iJiGGGJiJ_k6kC__x04".mark == WrongAnswer

  # DisappearColorSametime
  block:
    check "2005M05g05g06g65E2iE_OKOy__E02".mark == Accept
    check "2005M05g05g06g65E2iE_OyO8__E02".mark == WrongAnswer

  # DisappearColorMoreSametime
  block:
    check "600300200100p00pg_qKck__E02".mark == Accept
    check "600300200100p00pg_qKcI__E02".mark == WrongAnswer

  # DisappearCountSametime
  block:
    check "10090aj09jo_oscE__G0c".mark == Accept
    check "10090aj09jo_oscq__G0c".mark == WrongAnswer
    check "11011M16Me69S6Nc4CA4Ne6N96N_G46g__G0o".mark == Accept
    check "11011M16Me69S6Nc4CA4Ne6N96N_G464__G0o".mark == WrongAnswer

  # DisappearCountMoreSametime
  block:
    check "pp9b9rpr_ogogoe__H0b".mark == Accept
    check "pp9b9rpr_osouow__H0b".mark == WrongAnswer

  # DisappearPlace
  block:
    check "8w0wAcw_AuAE__I02".mark == Accept
    check "8w0wAcw_A4Au__I02".mark == WrongAnswer
    check "8w0wAcw_AuAE__I62".mark == NotSupport

  # DisappearPlaceMore
  block:
    check "8w0wAcw_AuAE__J02".mark == Accept
    check "8w0wAcw_A4Au__J02".mark == WrongAnswer

  # DisappearConnect
  block:
    check "M0hh0ia09r0ij8_e6gI__Q07".mark == Accept
    check "M0hh0ia09r0ij8_e2gC__Q07".mark == WrongAnswer

  # DisappearConnectMore
  block:
    check "M0hh0ia09r0ij8_e6gI__R07".mark == Accept
    check "M0hh0ia09r0ij8_e2gC__R07".mark == WrongAnswer
