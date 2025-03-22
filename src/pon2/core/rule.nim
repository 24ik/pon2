## This module implements Puyo Puyo rules.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, sugar, tables]
import ./[res]

type Rule* {.pure.} = enum
  ## Puyo Puyo rule.
  Tsu = "t"
  Water = "w"

# ------------------------------------------------
# Rule <-> string
# ------------------------------------------------

const StrToRule = collect:
  for rule in Rule:
    {$rule: rule}

func parseRule*(str: string): Res[Rule] {.inline.} =
  ## Returns the rule converted from the string representation.
  if str notin StrToRule:
    return Res[Rule].err "Invalid rule: {str}".fmt

  Res[Rule].ok StrToRule[str]
