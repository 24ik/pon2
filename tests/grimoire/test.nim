{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/[core]
import ../../src/pon2/app/[grimoire]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

block: # init, add
  let
    query = "field=0_rrrbbb&steps=rb&goal=0_0_2_0_"
    title = "title1"
    creators = @["creator1", "creator2"]
    source = "source1"
    sourceDetail = "sourceDetail1"

    entry1 = GrimoireEntry.init(query, title, creators, source, sourceDetail)
    entry2 = GrimoireEntry.init("field=1_ggpp.&steps=gpgp&goal=_0")

  check entry1 ==
    GrimoireEntry(
      query: query,
      moveCount: 1,
      goal: Goal.init(Chain, 2, Exact),
      title: title,
      creators: creators,
      source: source,
      sourceDetail: sourceDetail,
    )

  var grimoire1 = Grimoire.init
  grimoire1.add [entry1, entry2]

  let grimoire2 = Grimoire.init [entry1, entry2]

  check grimoire1 == grimoire2

  let
    moveCountOpt = Opt[int].ok 3
    kindOptOpt = Opt[Opt[GoalKind]].err
    hasClearColorOpt = Opt[bool].ok true
    sourceOpt = Opt[string].err

  check GrimoireMatcher.init(
    moveCountOpt,
    kindOptOpt,
    hasClearColorOpt,
    Opt[string].ok "タいトる",
    Opt[string].ok "CREATOR　２",
    sourceOpt,
  ) ==
    GrimoireMatcher(
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
  # `[]`, isReady, `isReady=`, len, matchedEntryIndices, moveCountMax, sources, match
  let
    entry0 = GrimoireEntry.init(
      "field=0_p.....op....pp...ggo...gppp.&steps=gp&goal=0_0_3_0_",
      creators = @["OrangeP"],
      source = "早大なぞぷよマスターズ2025",
      sourceDetail = "第1問",
    )
    entry1 = GrimoireEntry.init(
      "field=0_o..o..po.g..pg.ggopggppp&steps=gpgp&goal=1_0_2_0_",
      creators = @["OrangeP"],
      source = "早大なぞぷよマスターズ2025",
      sourceDetail = "第17問",
    )
    entry2 = GrimoireEntry.init(
      "field=0_b.....o.....bbr.bbobr.&steps=rbrb&goal=0_0_3_0_",
      creators = @["Pon!通"],
      source = "早大なぞぷよマスターズ2025",
      sourceDetail = "第9問",
    )
    entry3 = GrimoireEntry.init(
      "field=3_~.ypor..oprr..y.yy....y&steps=ypyyrp&goal=0_0_4_0_",
      creators = @["Pon!通"],
      source = "早大なぞぷよマスターズ2024",
      sourceDetail = "第31問",
    )
    entry4 = GrimoireEntry.init(
      "field=0_&steps=o1_0_0_0_0_0oyyo0_1_0_1_0_1oyyo1_0_0_0_1_1oyyo0_1_0_0_1_1oyyo0_0_1_0_1_1oyy&goal=_0",
      title = "流れ星",
      creators = @["π"],
      source = "早大なぞぷよマスターズ2022",
      sourceDetail = "第30問",
    )
    entry5 = GrimoireEntry.init(
      "field=0_pb.pb.bp.pb.oo.oo.pb.pb.pb.bp.oo.oo.bp.bb.pb.pp.oo.oo.bb.bp.pp.pb.&steps=pbppbbpbppbbpbpb&goal=0_0_8_0_0",
      title = "コラプサー",
      creators = @["π"],
      source = "早大なぞぷよマスターズ2020",
      sourceDetail = "第40問",
    )

  var grimoire = Grimoire.init [entry0, entry1, entry2, entry3, entry4, entry5]

  check grimoire[0] == entry0
  check grimoire[1] == entry1
  check not grimoire.isReady
  check grimoire.len == 6
  check grimoire.matchedEntryIndices == set[int16]({})
  check grimoire.moveCountMax == 10
  check grimoire.sources == newSeq[string]()

  grimoire.isReady = true

  check grimoire.isReady
  check grimoire.matchedEntryIndices == {0'i16, 1, 2, 3, 4, 5}
  check grimoire.sources ==
    @[
      "早大なぞぷよマスターズ2020", "早大なぞぷよマスターズ2022",
      "早大なぞぷよマスターズ2024", "早大なぞぷよマスターズ2025",
    ]

  grimoire.match GrimoireMatcher.init(moveCountOpt = Opt[int].ok 1)
  check grimoire.matchedEntryIndices == {0'i16}

  grimoire.match GrimoireMatcher.init(
    kindOptOpt = Opt[Opt[GoalKind]].ok Opt[GoalKind].ok Chain
  )
  check grimoire.matchedEntryIndices == {0'i16, 2, 3, 5}

  grimoire.match GrimoireMatcher.init(hasClearColorOpt = Opt[bool].ok true)
  check grimoire.matchedEntryIndices == {4'i16, 5}

  grimoire.match GrimoireMatcher.init(creatorOpt = Opt[string].ok "PoN")
  check grimoire.matchedEntryIndices == {2'i16, 3}

  grimoire.match GrimoireMatcher.init(titleOpt = Opt[string].ok "プサ")
  check grimoire.matchedEntryIndices == {5'i16}

  grimoire.match GrimoireMatcher.init(sourceOpt = Opt[string].ok "2025")
  check grimoire.matchedEntryIndices == {0'i16, 1, 2}

  grimoire.match GrimoireMatcher.init(
    moveCountOpt = Opt[int].ok 2,
    kindOptOpt = Opt[Opt[GoalKind]].ok Opt[GoalKind].ok Color,
  )
  check grimoire.matchedEntryIndices == {1'i16}
