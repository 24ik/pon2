{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/private/[tables]

block: # `[]`
  block: # Table
    let table = {1: "one", 2: "two"}.toTable
    check table[1] == Pon2Result[string].ok "one"
    check table[3].isErr

  block: # TableRef
    let table = {"three": 3.0, "four": 4.0, "five": 5.0}.newTable
    check table["four"] == Pon2Result[float].ok 4.0
    check table["FOUR"].isErr

  block: # OrderedTable
    let table = {'8': 8}.toOrderedTable
    check table['8'] == Pon2Result[int].ok 8
    check table['0'].isErr

  block: # OrderedTableRef
    let table = {1: @[1], 3: @[1, 2, 3], 2: @[1, 2]}.newOrderedTable
    check table[1] == Pon2Result[seq[int]].ok @[1]
    check table[0].isErr
