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

      let entry = GrimoireEntry.init(query, title, creators, source, sourceDetail)
      strs.add [
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
      if substrs.len != 8:
        return err errorMsg

      entries.add GrimoireEntry(
        query: substrs[0],
        rule: ?parseOrdinal[Rule](substrs[1]).context errorMsg,
        moveCount: ?substrs[2].parseInt.context errorMsg,
        goal: ?substrs[3].parseGoal(Pon2).context errorMsg,
        title: substrs[4],
        creators: substrs[5].split2 CreatorSep,
        source: substrs[6],
        sourceDetail: substrs[7],
      )

    ok entries
