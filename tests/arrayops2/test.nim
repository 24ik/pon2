{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/private/[arrayops2]

type EnumType = enum
  Foo
  Bar

block: # static size
  check initArrWith(3, "abc") == ["abc", "abc", "abc"]
  check initArrWith(0, 'd') == []

block: # enum
  check initArrWith[EnumType, seq[int]](@[2, 3]) == [@[2, 3], @[2, 3]]
