{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/private/[setutils]

block: # toSet
  check ['a', 'b', 'c', 'a'].toSet == {'a', 'b', 'c'}
