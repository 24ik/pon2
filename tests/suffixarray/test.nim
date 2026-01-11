{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/private/[suffixarray]

block:
  let suffixArray =
    SuffixArray.init ["すもも", "も", "もも", "も", "もも", "の", "うち"]
  check suffixArray.findAll("も") == {0'i16, 1, 2, 3, 4}
  check suffixArray.findAll("もも") == {0'i16, 2, 4}
  check suffixArray.findAll("う") == {6'i16}
  check suffixArray.findAll("ほ") == set[int16]({})
