## This module implements helpers for Nazo Puyo Grimoire used in GUI.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

when defined(js) or defined(nimsuggest):
  import std/[sequtils, strformat]
  import parsetoml
  import ../[strutils]
  import ../../[app]

  const
    Sep = "<pon2-grimoire-sep>"
    CreatorSep = "<pon2-grimoire-creatorsep>"

  proc toGrimoireEntryStrs*(str: string): Pon2Result[seq[string]] =
    # parse toml
    let table: TomlValueRef
    try:
      {.gcsafe.}:
        table = str.parseString
    except Exception as ex:
      table = nil
      return err ex.msg

    # entries
    let entriesVal = table.getOrDefault "entries"
    if entriesVal.isNil or entriesVal.kind != Array:
      return err "`entries` key with an array value is required"
    let entryElems = entriesVal.getElems

    var strs = newSeqOfCap[string](entryElems.len)
    for entryIndex, entryElem in entryElems:
      # ID
      let idVal = entryElem.getOrDefault "id"
      if idVal.isNil or idVal.kind != Int:
        return err "[Entry {entryIndex}] `id` key with a 16-bit signed integer value is required".fmt
      let id = idVal.getInt
      if id notin int16.low.int .. int16.high.int:
        return err "[Entry {entryIndex}] `id` key with a 16-bit signed integer value is required".fmt
      let id16 = id.int16

      # query
      let queryVal = entryElem.getOrDefault "query"
      if queryVal.isNil or queryVal.kind != String:
        return
          err "[Entry {entryIndex}] `query` key with a string value is required".fmt
      let query = queryVal.getStr

      # title
      let
        titleVal = entryElem.getOrDefault "title"
        title: string
      if titleVal.isNil:
        title = ""
      elif titleVal.kind == String:
        title = titleVal.getStr
      else:
        title = ""
        return err "[Entry {entryIndex}] `title` value should be string".fmt

      # creators
      let
        creatorsVal = entryElem.getOrDefault "creators"
        creators: seq[string]
      if creatorsVal.isNil:
        creators = @[]
      elif creatorsVal.kind == String:
        creators = @[creatorsVal.getStr]
      elif creatorsVal.kind == Array:
        let creatorsElems = creatorsVal.getElems
        if creatorsElems.anyIt it.kind != String:
          return err "[Entry {entryIndex}] all `creators` values should be string".fmt
        creators = creatorsElems.mapIt it.getStr
      else:
        return err "[Entry {entryIndex}] `creators` value should be string or array".fmt

      # source
      let
        sourceVal = entryElem.getOrDefault "source"
        source: string
      if sourceVal.isNil:
        source = ""
      elif sourceVal.kind == String:
        source = sourceVal.getStr
      else:
        source = ""
        return err "[Entry {entryIndex}] `source` value should be string".fmt

      # source detail
      let
        sourceDetailVal = entryElem.getOrDefault "sourceDetail"
        sourceDetail: string
      if sourceDetailVal.isNil:
        sourceDetail = ""
      elif sourceDetailVal.kind == String:
        sourceDetail = sourceDetailVal.getStr
      else:
        sourceDetail = ""
        return err "[Entry {entryIndex}] `sourceDetail` value should be string".fmt

      let entry = GrimoireEntry.init(id16, query, title, creators, source, sourceDetail)
      strs.add [
        $id16,
        query,
        $entry.rule.ord,
        $entry.moveCount,
        entry.goal.toUriQuery.unsafeValue,
        title,
        creators.join CreatorSep,
        source,
        sourceDetail,
      ].join Sep

    ok strs

  func parseGrimoireEntries*(strs: seq[string]): Pon2Result[seq[GrimoireEntry]] =
    ## Returns the grimoire entries converted from the run result.
    var entries = newSeqOfCap[GrimoireEntry](strs.len)

    for str in strs:
      let errorMsg = "Invalid grimoire entry: {str}".fmt

      let substrs = str.split Sep
      if substrs.len != 9:
        return err errorMsg

      entries.add GrimoireEntry(
        id: ?parseOrdinal[int16](substrs[0]).context errorMsg,
        query: substrs[1],
        rule: ?parseOrdinal[Rule](substrs[2]).context errorMsg,
        moveCount: ?substrs[3].parseInt.context errorMsg,
        goal: ?substrs[4].parseGoal(Pon2).context errorMsg,
        title: substrs[5],
        creators: substrs[6].split2 CreatorSep,
        source: substrs[7],
        sourceDetail: substrs[8],
      )

    ok entries
