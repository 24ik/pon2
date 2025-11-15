{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/private/[algorithm]

block: # product
  let seqs = @[@[1, 2, 3], @[4], @[5, 6]]
  check seqs.product ==
    @[@[3, 4, 6], @[2, 4, 6], @[1, 4, 6], @[3, 4, 5], @[2, 4, 5], @[1, 4, 5]]

  check [@["ab", "cd", "ef"]].product == @[@["ab"], @["cd"], @["ef"]]
  check newSeq[seq[bool]]().product == @[newSeq[bool]()]
