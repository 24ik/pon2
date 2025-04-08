{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/core/[rule]
import ../../src/pon2/private/[results2]

# ------------------------------------------------
# Rule <-> string
# ------------------------------------------------

block: # parseRule
  for rule in Rule:
    let ruleRes = parseRule $rule
    check ruleRes == Res[Rule].ok rule

  check "".parseRule.isErr
  check "T".parseRule.isErr
