{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/core/[rule]

# ------------------------------------------------
# Rule <-> string
# ------------------------------------------------

block: # parseRule
  for rule in Rule:
    let ruleRes = parseRule $rule
    check ruleRes == Res[Rule].ok rule

  check "".parseRule.isErr
  check "T".parseRule.isErr
