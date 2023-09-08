import options
import sequtils
import std/appdirs
import std/files
import std/paths
import tables
import times
import unittest
import uri

import nazopuyo_core
import puyo_core

import ../../src/pon2pkg/core/db

proc main* =
  # ------------------------------------------------
  # Save / Load
  # ------------------------------------------------

  # save, load
  block:
    let dbPath = getTempDir() / "pon2-test".Path / "nazo.json".Path
    if dbPath.fileExists:
      dbPath.removeFile

    var db = loadDatabase dbPath
    check db.len == 0

    db.add makeEmptyNazoPuyo()
    check db.len == 1

    db.saveDatabase dbPath
    check dbPath.fileExists

    let db2 = loadDatabase dbPath
    check db2.len == 1

  # ------------------------------------------------
  # Operation
  # ------------------------------------------------

  # add, find
  block:
    let dbPath = getTempDir() / "pon2-test".Path / "nazo.json".Path
    var db = loadDatabase dbPath
    db.clear
    check db.len == 0

    let
      nazo1 = "https://ishikawapuyo.net/simu/pn.html?r4AA3r_E1E1__200".parseUri.toNazoPuyo.get.nazoPuyo
      nazo2 = "https://ishikawapuyo.net/simu/pn.html?Mp6j92mS_o1q1__u03".parseUri.toNazoPuyo.get.nazoPuyo
    db.add nazo1
    db.add nazo2
    db.add nazo1, @["43\n3F".toPositions.get]

    check nazo1 in db
    check nazo2 in db
    check db.len == 2
    check db[nazo1].registerTime > db[nazo2].registerTime
    check db[nazo1].answers.len == 1
    check db[nazo2].answers.len == 0

    check db.find(moveCounts = some @[2.Positive]).toSeq.mapIt(it.nazoPuyo) in [@[nazo1, nazo2], @[nazo2, nazo1]]
    check db.find(moveCounts = some @[2.Positive], kinds = some @[CLEAR]).toSeq.mapIt(it.nazoPuyo) == @[nazo1]
    check db.find(kinds = some @[CHAIN_MORE]).toSeq.mapIt(it.nazoPuyo).len == 0

    db.del nazo2
    check nazo1 in db
    check nazo2 notin db
    check db.len == 1
