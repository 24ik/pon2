## This module implements Puyo Puyo rules.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat]
import ../[utils]

export utils

type Rule* {.pure.} = enum ## Puyo Puyo rule.
  Tsu = "通"
  Spinner = "だいかいてん"
  CrossSpinner = "クロスかいてん"
  Water = "すいちゅう"

# ------------------------------------------------
# Rule <-> string
# ------------------------------------------------

func parseRule*(str: string): Pon2Result[Rule] {.inline, noinit.} =
  ## Returns the rule converted from the string representation.
  for rule in Rule:
    if str == $rule:
      return ok rule

  err "Invalid rule: {str}".fmt
