## This module implements rules.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar, tables]

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

func parseRule*(str: string): Rule {.inline.} =
  ## Converts the string representation to the rule.
  ## If `str` is not a valid representation, `ValueError` is raised.
  try:
    result = StrToRule[str]
  except KeyError:
    result = Rule.low # HACK: dummy to suppress warning
    raise newException(ValueError, "Invalid rule: " & str)
