{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/private/[tables2]

block: # getRes
  block: # Table
    let table = {1: "one", 2: "two"}.toTable
    check table.getRes(1) == Res[string].ok "one"
    check table.getRes(3).isErr

  block: # TableRef
    let table = {"three": 3.0, "four": 4.0, "five": 5.0}.newTable
    check table.getRes("four") == Res[float].ok 4.0
    check table.getRes("FOUR").isErr

  block: # OrderedTable
    let table = {'8': 8}.toOrderedTable
    check table.getRes('8') == Res[int].ok 8
    check table.getRes('0').isErr

  block: # OrderedTableRef
    let table = {1: @[1], 3: @[1, 2, 3], 2: @[1, 2]}.newOrderedTable
    check table.getRes(1) == Res[seq[int]].ok @[1]
    check table.getRes(0).isErr
