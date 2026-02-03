{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/[core]
import ../../src/pon2/app/[grimoire, simulator]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

block: # init, add
  let
    id = 10'i16
    query = "field=0_rrrbbb&steps=rb&goal=0_0_2_0_"
    title = "title1"
    creators = @["creator1", "creator2"]
    source = "source1"
    sourceDetail = "sourceDetail1"

    entry1 = GrimoireEntry.init(id, query, title, creators, source, sourceDetail)
    entry2 = GrimoireEntry.init(20, "field=1_ggpp.&steps=gpgp&goal=_0")

  check entry1 ==
    GrimoireEntry(
      id: id,
      query: query,
      rule: Tsu,
      moveCount: 1,
      goal: Goal.init(Chain, 2, Exact),
      title: title,
      creators: creators,
      source: source,
      sourceDetail: sourceDetail,
    )

  var grimoire1 = Grimoire.init
  grimoire1.add [entry1, entry2]

  let grimoire2 = Grimoire.init([entry1, entry2], SimulatorKeyBindPattern.Pon2)

  check grimoire1 == grimoire2

  let
    ruleOpt = Opt[Rule].err
    moveCountOpt = Opt[int].ok 3
    kindOptOpt = Opt[Opt[GoalKind]].err
    hasClearColorOpt = Opt[bool].ok true
    sourceOpt = Opt[string].err

  check GrimoireMatcher.init(
    ruleOpt,
    moveCountOpt,
    kindOptOpt,
    hasClearColorOpt,
    Opt[string].ok "タいトる",
    Opt[string].ok "CREATOR　２",
    sourceOpt,
  ) ==
    GrimoireMatcher(
      ruleOpt: ruleOpt,
      moveCountOpt: moveCountOpt,
      kindOptOpt: kindOptOpt,
      hasClearColorOpt: hasClearColorOpt,
      titleOpt: Opt[string].ok "たいとる",
      creatorOpt: Opt[string].ok "creator 2",
      sourceOpt: sourceOpt,
    )

# ------------------------------------------------
# Property, Match
# ------------------------------------------------

block:
  # getEntry, entryIds, isReady, `isReady=`, len, matchedEntryIds, moveCounts, sources, match
  let
    entry0 = GrimoireEntry.init(
      0,
      "field=0_p.....op....pp...ggo...gppp.&steps=gp&goal=0_0_3_0_",
      creators = @["OrangeP"],
      source = "早大なぞぷよマスターズ2025",
      sourceDetail = "第1問",
    )
    entry1 = GrimoireEntry.init(
      100,
      "field=0_o..o..po.g..pg.ggopggppp&steps=gpgp&goal=1_0_2_0_",
      creators = @["OrangeP"],
      source = "早大なぞぷよマスターズ2025",
      sourceDetail = "第17問",
    )
    entry2 = GrimoireEntry.init(
      20,
      "field=0_b.....o.....bbr.bbobr.&steps=rbrb&goal=0_0_3_0_",
      creators = @["Pon!通"],
      source = "早大なぞぷよマスターズ2025",
      sourceDetail = "第9問",
    )
    entry3 = GrimoireEntry.init(
      3,
      "field=3_~.ypor..oprr..y.yy....y&steps=ypyyrp&goal=0_0_4_0_",
      creators = @["Pon!通"],
      source = "早大なぞぷよマスターズ2024",
      sourceDetail = "第31問",
    )
    entry4 = GrimoireEntry.init(
      40,
      "field=0_&steps=o1_0_0_0_0_0oyyo0_1_0_1_0_1oyyo1_0_0_0_1_1oyyo0_1_0_0_1_1oyyo0_0_1_0_1_1oyy&goal=_0",
      title = "流れ星",
      creators = @["π"],
      source = "早大なぞぷよマスターズ2022",
      sourceDetail = "第30問",
    )
    entry5 = GrimoireEntry.init(
      5,
      "field=0_pb.pb.bp.pb.oo.oo.pb.pb.pb.bp.oo.oo.bp.bb.pb.pp.oo.oo.bb.bp.pp.pb.&steps=pbppbbpbppbbpbpb&goal=0_0_8_0_0",
      title = "コラプサー",
      creators = @["π"],
      source = "早大なぞぷよマスターズ2020",
      sourceDetail = "第40問",
    )

  var grimoire = Grimoire.init [entry0, entry1, entry2, entry3, entry4, entry5]

  check grimoire.getEntry(100).isErr
  check grimoire.getEntry(200).isErr
  check grimoire.entryIds == set[int16]({})
  check not grimoire.isReady
  check grimoire.len == 6
  check grimoire.matchedEntryIds == set[int16]({})
  check grimoire.moveCounts == newSeq[int]()
  check grimoire.sources == newSeq[string]()

  grimoire.isReady = true

  check grimoire.getEntry(100) == Pon2Result[GrimoireEntry].ok entry1
  check grimoire.getEntry(200).isErr
  check grimoire.entryIds == {0'i16, 100, 20, 3, 40, 5}
  check grimoire.isReady
  check grimoire.matchedEntryIds == {0'i16, 100, 20, 3, 40, 5}
  check grimoire.moveCounts == @[1, 2, 3, 8, 10]
  check grimoire.sources ==
    @[
      "早大なぞぷよマスターズ2020", "早大なぞぷよマスターズ2022",
      "早大なぞぷよマスターズ2024", "早大なぞぷよマスターズ2025",
    ]

  grimoire.match GrimoireMatcher.init(ruleOpt = Opt[Rule].ok Water)
  check grimoire.matchedEntryIds == {3'i16}

  grimoire.match GrimoireMatcher.init(moveCountOpt = Opt[int].ok 1)
  check grimoire.matchedEntryIds == {0'i16}

  grimoire.match GrimoireMatcher.init(
    kindOptOpt = Opt[Opt[GoalKind]].ok Opt[GoalKind].ok Chain
  )
  check grimoire.matchedEntryIds == {0'i16, 20, 3, 5}

  grimoire.match GrimoireMatcher.init(hasClearColorOpt = Opt[bool].ok true)
  check grimoire.matchedEntryIds == {40'i16, 5}

  grimoire.match GrimoireMatcher.init(creatorOpt = Opt[string].ok "PoN")
  check grimoire.matchedEntryIds == {20'i16, 3}

  grimoire.match GrimoireMatcher.init(titleOpt = Opt[string].ok "プサ")
  check grimoire.matchedEntryIds == {5'i16}

  grimoire.match GrimoireMatcher.init(sourceOpt = Opt[string].ok "2025")
  check grimoire.matchedEntryIds == {0'i16, 100, 20}

  grimoire.match GrimoireMatcher.init(
    moveCountOpt = Opt[int].ok 2,
    kindOptOpt = Opt[Opt[GoalKind]].ok Opt[GoalKind].ok Color,
  )
  check grimoire.matchedEntryIds == {100'i16}
