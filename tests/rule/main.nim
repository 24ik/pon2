{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2pkg/core/[rule {.all.}]

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
