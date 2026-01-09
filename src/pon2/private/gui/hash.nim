## This module implements hash part processings.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  import ../../[app]
  import ../../private/[assign, dom, strutils, uri]

  # ------------------------------------------------
  # Grimoire
  # ------------------------------------------------

  type GrimoireHashData* = object
    matcher*: GrimoireMatcher
    matchSolvedOpt*: Opt[bool]
    pageIndex*: int

  const
    RuleKey = "rule"
    MoveCountKey = "movecount"
    KindKey = "kind"
    ClearColorKey = "clearcolor"
    TitleKey = "title"
    CreatorKey = "creator"
    SourceKey = "source"
    SolvedKey = "solved"
    PageKey = "page"

    ErrVal = "~"

  func parseGrimoireHashData*(hashPart: cstring): GrimoireHashData =
    ## Returns the grimoire matcher and the page index converted from the hash part.
    var
      ruleOpt = Opt[Rule].err
      moveCountOpt = Opt[int].err
      kindOptOpt = Opt[Opt[GoalKind]].err
      hasClearColorOpt = Opt[bool].err
      titleOpt = Opt[string].err
      creatorOpt = Opt[string].err
      sourceOpt = Opt[string].err
      solvedOpt = Opt[bool].err
      pageIndex = 0

    for (key, val) in ($hashPart).substr(1).decodeQuery:
      let decodedVal = val.decodeUrl
      case key
      of RuleKey:
        parseOrdinal[Rule](decodedVal).isErrOr:
          ruleOpt.ok value
      of MoveCountKey:
        decodedVal.parseInt.isErrOr:
          if value > 0:
            moveCountOpt.ok value
      of KindKey:
        if decodedVal == ErrVal:
          kindOptOpt.ok Opt[GoalKind].err
        else:
          parseOrdinal[GoalKind](decodedVal).isErrOr:
            kindOptOpt.ok Opt[GoalKind].ok value
      of ClearColorKey:
        decodedVal.parseInt.isErrOr:
          hasClearColorOpt.ok value.bool
      of TitleKey:
        titleOpt.ok decodedVal
      of CreatorKey:
        creatorOpt.ok decodedVal
      of SourceKey:
        sourceOpt.ok decodedVal
      of SolvedKey:
        decodedVal.parseInt.isErrOr:
          solvedOpt.ok value.bool
      of PageKey:
        decodedVal.parseInt.isErrOr:
          if value > 0:
            pageIndex.assign value
      else:
        discard

    GrimoireHashData(
      matcher: GrimoireMatcher.init(
        ruleOpt, moveCountOpt, kindOptOpt, hasClearColorOpt, titleOpt, creatorOpt,
        sourceOpt,
      ),
      matchSolvedOpt: solvedOpt,
      pageIndex: pageIndex,
    )

  proc updateHash(key, val: string) =
    ## Updates the hash part with the key and value.
    let newHashBody =
      ($window.location.hash).substr(1).updatedQuery(key, val, removeEmptyVal = true)

    window.location.hash.assign (if newHashBody.len == 0: ""
    else: '#' & newHashBody).cstring

  proc updateGrimoireHashWithRule*(ruleOpt: Opt[Rule]) =
    ## Updates the hash part with the rule.
    RuleKey.updateHash if ruleOpt.isOk:
      $ruleOpt.unsafeValue.ord
    else:
      ""

  proc updateGrimoireHashWithMoveCount*(moveCountOpt: Opt[int]) =
    ## Updates the hash part with the move count.
    MoveCountKey.updateHash if moveCountOpt.isOk:
      $moveCountOpt.unsafeValue
    else:
      ""

  proc updateGrimoireHashWithKind*(kindOptOpt: Opt[Opt[GoalKind]]) =
    ## Updates the hash part with the goal kind.
    KindKey.updateHash (
      if kindOptOpt.isOk:
        let kindOpt = kindOptOpt.unsafeValue
        if kindOpt.isOk:
          $kindOpt.unsafeValue.ord
        else:
          ErrVal
      else:
        ""
    )

  proc updateGrimoireHashWithClearColor*(hasClearColorOpt: Opt[bool]) =
    ## Updates the hash part with the clear color.
    ClearColorKey.updateHash if hasClearColorOpt.isOk:
      $hasClearColorOpt.unsafeValue.ord
    else:
      ""

  proc updateGrimoireHashWithTitle*(titleOpt: Opt[string]) =
    ## Updates the hash part with the title.
    TitleKey.updateHash if titleOpt.isOk:
      $titleOpt.unsafeValue.encodeUrl
    else:
      ""

  proc updateGrimoireHashWithCreator*(creatorOpt: Opt[string]) =
    ## Updates the hash part with the creator.
    CreatorKey.updateHash if creatorOpt.isOk:
      $creatorOpt.unsafeValue.encodeUrl
    else:
      ""

  proc updateGrimoireHashWithSource*(sourceOpt: Opt[string]) =
    ## Updates the hash part with the source.
    SourceKey.updateHash if sourceOpt.isOk:
      $sourceOpt.unsafeValue.encodeUrl
    else:
      ""

  proc updateGrimoireHashWithSolved*(solvedOpt: Opt[bool]) =
    ## Updates the hash part with the solved status.
    SolvedKey.updateHash if solvedOpt.isOk:
      $solvedOpt.unsafeValue.ord
    else:
      ""

  proc updateGrimoireHashWithPageIndex*(pageIndex: int) =
    ## Updates the hash part with the page index.
    PageKey.updateHash $pageIndex
