{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar, unittest]
import ../../src/pon2/private/[assign]

block: # assign
  type MyObj = object
    intVal: int
    strVal: string
    arrayVal: array[2, char]
    seqVal: seq[set[int8]]

  let myObj =
    MyObj(intVal: 5678, strVal: "def", arrayVal: ['X', 'W'], seqVal: @[{7'i8}, {}, {}])

  check 1234.dup(assign(myObj.intVal)) == myObj.intVal
  check "abc".dup(assign(myObj.strVal)) == myObj.strVal
  check ['Z', 'Y'].dup(assign(myObj.arrayVal)) == myObj.arrayVal
  check @[{4'i8}, {5'i8, 6'i8}].dup(assign(myObj.seqVal)) == myObj.seqVal
  check MyObj(intVal: 0, strVal: "", arrayVal: ['a', 'b'], seqVal: @[]).dup(
    assign(myObj)
  ) == myObj
