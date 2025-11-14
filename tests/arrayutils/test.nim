{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/private/[arrayutils]

type MyEnum = enum
  Foo
  Bar

block: # static size
  check 3.initArrayWith("abc") == ["abc", "abc", "abc"]
  check 0.initArrayWith('d') == []

block: # enum
  check MyEnum.initArrayWith(@[2, 3]) == [@[2, 3], @[2, 3]]
