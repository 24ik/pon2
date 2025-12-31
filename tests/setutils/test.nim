{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar, unittest]
import ../../src/pon2/private/[setutils]

block: # `+=`, `-=`, `*=`
  let
    s1 = {'x', 'y', 'z'}
    s2 = {'w', 'x', 'y'}

  check s1.dup(`+=`(s2)) == s1 + s2
  check s1.dup(`-=`(s2)) == s1 - s2
  check s1.dup(`*=`(s2)) == s1 * s2

block: # toSet
  check ['a', 'b', 'c', 'a'].toSet == {'a', 'b', 'c'}
