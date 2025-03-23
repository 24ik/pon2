## This module implements Puyo Puyo rules.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, sugar, tables]
import results

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

func parseRule*(str: string): Result[Rule, string] {.inline.} =
  ## Returns the rule converted from the string representation.
  if str in StrToRule:
    Result[Rule, string].ok StrToRule[str]
  else:
    Result[Rule, string].err "Invalid rule: {str}".fmt
