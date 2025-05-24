{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[algorithm, sugar, unittest]
import ../../src/pon2/private/[utils]

block: # toggle
  check not true.dup(toggle)
  check false.dup(toggle)

block: # incRot, decRot
  var x = int.high

  x.incRot
  check x == int.low

  x.incRot
  check x == int.low.succ

  x.decRot
  check x == int.low

  x.decRot
  check x == int.high

block: # product2
  let seqs = @[@[1, 2, 3], @[4], @[5, 6]]
  check seqs.product2 == seqs.product

  check [@["ab", "cd", "ef"]].product2 == @[@["ab"], @["cd"], @["ef"]]
  check newSeq[seq[bool]]().product2 == @[newSeq[bool]()]

block: # toSet2
  check ['a', 'b', 'c'].toSet2 == {'a', 'b', 'c'}
