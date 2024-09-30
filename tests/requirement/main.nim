{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/core/[host, requirement]

proc main*() =
  # ------------------------------------------------
  # Requirement <-> string / URI
  # ------------------------------------------------

  # `$`, toUriQuery, parseRequirement
  block:
    # requirement w/ color
    block:
      let
        req = Requirement(
          kind: Clear, color: RequirementColor.Garbage, number: RequirementNumber.low
        )
        str = "おじゃまぷよ全て消すべし"
        ikUri = "req-kind=0&req-color=6"
        ishikawaUri = "260"

      check $req == str
      check req.toUriQuery(Ik) == ikUri
      check req.toUriQuery(Ishikawa) == ishikawaUri
      check req.toUriQuery(Ips) == ishikawaUri
      check str.parseRequirement == req
      check ikUri.parseRequirement(Ik) == req
      check ishikawaUri.parseRequirement(Ishikawa) == req

    # requirement w/ num
    block:
      let
        req = Requirement(kind: Chain, number: 5.RequirementNumber)
        str = "5連鎖するべし"
        ikUri = "req-kind=5&req-number=5"
        ishikawaUri = "u05"

      check $req == str
      check req.toUriQuery(Ik) == ikUri
      check req.toUriQuery(Ishikawa) == ishikawaUri
      check req.toUriQuery(Ips) == ishikawaUri
      check str.parseRequirement == req
      check ikUri.parseRequirement(Ik) == req
      check ishikawaUri.parseRequirement(Ishikawa) == req

    # requirement w/ color and number
    block:
      let
        req = Requirement(
          kind: ChainMoreClear, color: RequirementColor.Red, number: 3.RequirementNumber
        )
        str = "3連鎖以上&赤ぷよ全て消すべし"
        ikUri = "req-kind=8&req-color=1&req-number=3"
        ishikawaUri = "x13"

      check $req == str
      check req.toUriQuery(Ik) == ikUri
      check req.toUriQuery(Ishikawa) == ishikawaUri
      check req.toUriQuery(Ips) == ishikawaUri
      check str.parseRequirement == req
      check ikUri.parseRequirement(Ik) == req
      check ishikawaUri.parseRequirement(Ishikawa) == req
