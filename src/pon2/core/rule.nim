## This module implements Puyo Puyo rules.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, sugar, tables]
import results
import ../private/[misc]

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
  let ruleRes = StrToRule.getRes str
  if ruleRes.isOk:
    Result[Rule, string].ok ruleRes.value
  else:
    Result[Rule, string].err "Invalid rule: {str}".fmt
