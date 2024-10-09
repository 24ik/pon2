{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[options, unittest]
import ../../src/pon2/core/[fqdn, requirement]

proc main*() =
  # ------------------------------------------------
  # Property
  # ------------------------------------------------

  # isSupported
  block:
    check initRequirement(Clear, RequirementColor.Garbage).isSupported
    check initRequirement(Chain, 5).isSupported
    check initRequirement(DisappearPlace, RequirementColor.Red, 1).isSupported
    check not initRequirement(DisappearPlace, RequirementColor.Garbage, 1).isSupported

    # kind, color, number, `kind=`, `color=`, `number=`
    block:
      var req = initRequirement(ChainClear, RequirementColor.Green, 4)
      check req.kind == ChainClear
      check req.color == RequirementColor.Green
      check req.number == 4

      req.kind = Clear
      check req.kind == Clear
      check req.color == RequirementColor.Green
      expect UnpackDefect:
        discard req.number

      req.kind = DisappearColor
      check req.kind == DisappearColor
      expect UnpackDefect:
        discard req.color
      check req.number == 0

      req.kind = DisappearPlaceMore
      check req.kind == DisappearPlaceMore
      check req.color == All
      check req.number == 0

  # ------------------------------------------------
  # Requirement <-> string / URI
  # ------------------------------------------------

  # `$`, toUriQuery, parseRequirement
  block:
    # requirement w/ color
    block:
      let
        req = initRequirement(Clear, RequirementColor.Garbage)
        str = "おじゃまぷよ全て消すべし"
        pon2Uri = "req-kind=0&req-color=6"
        ishikawaUri = "260"

      check $req == str
      check req.toUriQuery(Pon2) == pon2Uri
      check req.toUriQuery(Ishikawa) == ishikawaUri
      check req.toUriQuery(Ips) == ishikawaUri
      check str.parseRequirement == req
      check pon2Uri.parseRequirement(Pon2) == req
      check ishikawaUri.parseRequirement(Ishikawa) == req

    # requirement w/ num
    block:
      let
        req = initRequirement(Chain, 5)
        str = "5連鎖するべし"
        pon2Uri = "req-kind=5&req-number=5"
        ishikawaUri = "u05"

      check $req == str
      check req.toUriQuery(Pon2) == pon2Uri
      check req.toUriQuery(Ishikawa) == ishikawaUri
      check req.toUriQuery(Ips) == ishikawaUri
      check str.parseRequirement == req
      check pon2Uri.parseRequirement(Pon2) == req
      check ishikawaUri.parseRequirement(Ishikawa) == req

    # requirement w/ color and number
    block:
      let
        req = initRequirement(ChainMoreClear, RequirementColor.Red, 3)
        str = "3連鎖以上&赤ぷよ全て消すべし"
        pon2Uri = "req-kind=8&req-color=1&req-number=3"
        ishikawaUri = "x13"

      check $req == str
      check req.toUriQuery(Pon2) == pon2Uri
      check req.toUriQuery(Ishikawa) == ishikawaUri
      check req.toUriQuery(Ips) == ishikawaUri
      check str.parseRequirement == req
      check pon2Uri.parseRequirement(Pon2) == req
      check ishikawaUri.parseRequirement(Ishikawa) == req
