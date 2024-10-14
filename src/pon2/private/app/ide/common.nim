## This module implements helper functions for the IDE.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, uri]
import ../../[misc]
import ../../../app/[ide, nazopuyo, simulator]
import ../../../core/[nazopuyo, requirement, rule]

# ------------------------------------------------
# X
# ------------------------------------------------

const RuleDescriptions: array[Rule, string] = ["通", "すいちゅう"]

proc toXLink*(ide: Ide, withPositions: bool): Uri {.inline.} =
  ## Returns the URI for posting to X.
  let ideUri = ide.toUri withPositions

  case ide.simulator[].kind
  of Nazo:
    ide.simulator[].nazoPuyoWrapBeforeMoves.get:
      let
        ruleStr =
          if ide.simulator[].rule == Tsu:
            ""
          else:
            RuleDescriptions[ide.simulator[].rule]
        moveCount = wrappedNazoPuyo.moveCount
        reqStr = $wrappedNazoPuyo.requirement

      result = initXLink(&"{ruleStr}{moveCount}手・{reqStr}", "なぞぷよ", ideUri)
  of Regular:
    result = initXLink(uri = ideUri)
