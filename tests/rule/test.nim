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
  check "通".parseRule == Pon2Result[Rule].ok Rule.Tsu
  check "だいかいてん".parseRule == Pon2Result[Rule].ok Spinner
  check "クロスかいてん".parseRule == Pon2Result[Rule].ok CrossSpinner
  check "すいちゅう".parseRule == Pon2Result[Rule].ok Rule.Water
  check "".parseRule.isErr
