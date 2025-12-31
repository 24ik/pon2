{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[random, unittest]
import ../../src/pon2/[core]
import ../../src/pon2/app/[grimoire]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

block: # init, add
  let entry1 = NazoPuyoEntry.init(
    "field=0_rrrbbb&steps=rb&goal=0_0_2_0_", "author1", "title1", "source1"
  )
  check entry1 ==
    NazoPuyoEntry(
      query: "field=0_rrrbbb&steps=rb&goal=0_0_2_0_",
      author: "author1",
      title: "title1",
      source: "source1",
    )
  let entry2 = NazoPuyoEntry.init("field=1_ggpp.&steps=gpgp&goal=_0")

  var
    rng = 123.initRand
    grimoire1 = NazoPuyoGrimoire.init(rng)
  grimoire1.add [entry1, entry2]

  let grimoire2 = NazoPuyoGrimoire.init(rng, [entry1, entry2])

  check grimoire1 == grimoire2

# ------------------------------------------------
# Property, Match
# ------------------------------------------------

block: # `[]`, len, matchedEntryIndices, match
  let
    entry0 = NazoPuyoEntry.init(
      "field=0_p.....op....pp...ggo...gppp.&steps=gp&goal=0_0_3_0_",
      author = "OrangeP",
      source = "早大なぞぷよマスターズ2025",
    )
    entry1 = NazoPuyoEntry.init(
      "field=0_o..o..po.g..pg.ggopggppp&steps=gpgp&goal=1_0_2_0_",
      author = "OrangeP",
      source = "早大なぞぷよマスターズ2025",
    )
    entry2 = NazoPuyoEntry.init(
      "field=0_b.....o.....bbr.bbobr.&steps=rbrb&goal=0_0_3_0_",
      author = "Pon!通",
      source = "早大なぞぷよマスターズ2025",
    )
    entry3 = NazoPuyoEntry.init(
      "field=3_~.ypor..oprr..y.yy....y&steps=ypyyrp&goal=0_0_4_0_",
      author = "Pon!通",
      source = "早大なぞぷよマスターズ2024",
    )
    entry4 = NazoPuyoEntry.init(
      "field=0_&steps=o1_0_0_0_0_0oyyo0_1_0_1_0_1oyyo1_0_0_0_1_1oyyo0_1_0_0_1_1oyyo0_0_1_0_1_1oyy&goal=_0",
      author = "π",
      source = "早大なぞぷよマスターズ2022",
    )
    entry5 = NazoPuyoEntry.init(
      "field=0_pb.pb.bp.pb.oo.oo.pb.pb.pb.bp.oo.oo.bp.bb.pb.pp.oo.oo.bb.bp.pp.pb.&steps=pbppbbpbppbbpbpb&goal=0_0_8_0_0",
      author = "π",
      title = "コラプサー",
      source = "早大なぞぷよマスターズ2020",
    )

  var
    rng = 123.initRand
    grimoire =
      NazoPuyoGrimoire.init(rng, [entry0, entry1, entry2, entry3, entry4, entry5])

  check grimoire[0] == entry0.query.parseNazoPuyo(Pon2).unsafeValue
  check grimoire[1] == entry1.query.parseNazoPuyo(Pon2).unsafeValue
  check grimoire.len == 0
  check grimoire.matchedEntryIndices == newSeq[int]()

  grimoire.isReady = true

  check grimoire.len == 6
  check grimoire.matchedEntryIndices == newSeq[int]()

  grimoire.match NazoPuyoMatcher.init(moveCountOpt = Opt[int].ok 1)
  check grimoire.matchedEntryIndices == @[0]

  grimoire.match NazoPuyoMatcher.init(
    kindOptOpt = Opt[Opt[GoalKind]].ok Opt[GoalKind].ok Chain
  )
  check grimoire.matchedEntryIndices == @[0, 2, 3, 5]

  grimoire.match NazoPuyoMatcher.init(
    clearColorOptOpt = Opt[Opt[GoalColor]].ok Opt[GoalColor].ok All
  )
  check grimoire.matchedEntryIndices == @[4, 5]

  grimoire.match NazoPuyoMatcher.init(authorOpt = Opt[string].ok "Pon!通")
  check grimoire.matchedEntryIndices == @[2, 3]

  grimoire.match NazoPuyoMatcher.init(titleOpt = Opt[string].ok "コラプサー")
  check grimoire.matchedEntryIndices == @[5]

  grimoire.match NazoPuyoMatcher.init(
    sourceOpt = Opt[string].ok "早大なぞぷよマスターズ2025"
  )
  check grimoire.matchedEntryIndices == @[0, 1, 2]

  grimoire.match NazoPuyoMatcher.init(
    moveCountOpt = Opt[int].ok 2,
    kindOptOpt = Opt[Opt[GoalKind]].ok Opt[GoalKind].ok Color,
  )
  check grimoire.matchedEntryIndices == @[1]
