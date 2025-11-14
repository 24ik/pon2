{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar, unittest]
import ../../src/pon2/private/[assign]

block: # regular type
  let
    intVal = 5678
    strVal = "def"
    arrVal = ['X', 'W']
    seqVal = @[{7'i8}, {}, {}]

  check 1234.dup(assign(_, intVal)) == intVal
  check "abc".dup(assign(_, strVal)) == strVal
  check ['Z', 'Y'].dup(assign(_, arrVal)) == arrVal
  check @[{4'i8}, {5'i8, 6'i8}].dup(assign(_, seqVal)) == seqVal
