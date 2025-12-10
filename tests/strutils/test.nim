{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar, unittest]
import ../../src/pon2/private/[strutils]

block: # parseInt
  check "123".parseInt == Pon2Result[int].ok 123
  check "xyz".parseInt.isErr

block: # parseOrdinal
  check parseOrdinal[bool]("0") == Pon2Result[bool].ok false
  check parseOrdinal[char]($'x'.ord) == Pon2Result[char].ok 'x'

  check parseOrdinal[bool]("2").isErr

block: # split2
  proc checkSplit2(str, sep: string, res: seq[string], maxsplit = -1) =
    check str.split2(sep, maxsplit) == res

    let strs = collect:
      for s in str.split2(sep, maxsplit):
        s
    check strs == res

  ".a.bc.def.".checkSplit2 ".", @["", "a", "bc", "def", ""]
  "a---b".checkSplit2 "--", @["a", "-b"]

  "abc".checkSplit2 "", @["abc"]
  "abc".checkSplit2 "x", @["abc"]

  "a+b+c".checkSplit2 "+", @["a+b+c"], 0
  "a+b+c".checkSplit2 "+", @["a", "b+c"], 1
  "a+b+c".checkSplit2 "+", @["a", "b", "c"], 2
  "a+b+c".checkSplit2 "+", @["a", "b", "c"], 3

  "".checkSplit2 "", @[]
  "".checkSplit2 "x", @[]
  "".checkSplit2 "x", @[], 1
