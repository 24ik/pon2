{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/core/[rule]

proc main*() =
  # ------------------------------------------------
  # Rule <-> string
  # ------------------------------------------------

  # parseRule
  block:
    for rule in Rule:
      check ($rule).parseRule == rule

    expect ValueError:
      discard "".parseRule
    expect ValueError:
      discard "T".parseRule
