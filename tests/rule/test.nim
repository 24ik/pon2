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
  check "通".parseRule == StrErrorResult[Rule].ok Rule.Tsu
  check "だいかいてん".parseRule == StrErrorResult[Rule].ok Spinner
  check "クロスかいてん".parseRule == StrErrorResult[Rule].ok CrossSpinner
  check "すいちゅう".parseRule == StrErrorResult[Rule].ok Rule.Water
  check "".parseRule.isErr
