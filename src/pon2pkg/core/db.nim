## This module implements a database to store the nazo puyo.
##

import options
import sequtils
import strformat
import strutils
import sugar
import times

import nazopuyo_core
import os
import puyo_core
import tiny_sqlite

import ./util

const
  DbFileName = "nazo.db"

  TableName = "nazoTable"

  UrlColName = "url"
  KindColName = "kind"
  MoveNumColName = "moveNum"
  SaturateColName = "saturate"
  TimeColName = "time"

proc connectDb*(dbFile = DataDir / DbFileName): Option[DbConn] {.inline.} =
  ## Connects to the nazo puyo database.
  ## If connections fails, returns none.
  if dbFile.dirExists:
    return

  dbFile.parentDir.createDir

  let needCreateTable = not dbFile.fileExists
  result = some dbFile.openDatabase
  if needCreateTable:
    result.get.execScript &"""
CREATE TABLE {TableName} (
  {UrlColName}       TEXT NOT NULL,
  {KindColName}      INTEGER NOT NULL,
  {MoveNumColName}   INTEGER NOT NULL,
  {SaturateColName}  INTEGER NOT NULL,
  {TimeColName}      TEXT NOT NULL
)"""

proc contains(db: DbConn, url: string): bool {.inline.} =
  ## Returns true if the nazo puyo represented by the url is in the database.
  for _ in db.iterate &"SELECT * FROM {TableName} WHERE {UrlColName} = '{url}'":
    return true

proc contains(db: DbConn, nazo: Nazo): bool {.inline.} =
  ## Returns true if the nazo puyo is in the database.
  nazo.toUrl in db

proc insertCore(db: DbConn, nazo: Nazo): bool {.inline, discardable.} =
  ## Inserts the nazo puyo to the database without commit.
  ## If the nazo puyo is already in the database, not inserted and returns false.
  if nazo in db:
    return false

  db.exec(
    &"INSERT INTO {TableName} VALUES (?, ?, ?, ?, ?)",
    nazo.toUrl,
    nazo.req.kind.ord,
    nazo.moveNum,
    (
      nazo.req.kind in {CHAIN, CHAIN_MORE, CHAIN_CLEAR, CHAIN_MORE_CLEAR} and
      nazo.env.colorNum == nazo.req.num.get * 4
    ).int,
    $now().utc,
  )
  return true

proc insert*(db: DbConn, nazo: Nazo, commit = true): bool {.inline, discardable.} =
  ## Inserts the nazo puyo to the database.
  ## If the nazo puyo is already in the database, not inserted and returns false.
  if commit:
    db.transaction:
      return db.insertCore nazo
  else:
    return db.insertCore nazo

proc deleteCore(db: DbConn, url: string): bool {.inline, discardable.} =
  ## Deletes the nazo puyo represented by the url from the database without commit.
  ## If the nazo puyo is not in the database, returns false.
  if url notin db:
    return false

  db.exec(&"DELETE FROM {TableName} WHERE {UrlColName} = '{url}'")
  return true

proc delete*(db: DbConn, url: string, commit = true): bool {.inline, discardable.} =
  ## Deletes the nazo puyo represented by the url from the database.
  ## If the nazo puyo is not in the database, returns false.
  if commit:
    db.transaction:
      return db.deleteCore url
  else:
    return db.deleteCore url

iterator search*(
  db: DbConn,
  kinds: openArray[RequirementKind] = [],
  moveNums: openArray[Positive] = [],
  saturates: openArray[bool] = [],
  timeIntervals: openArray[tuple[start: Option[DateTime], stop: Option[DateTime]]] = [],
): string {.inline.} =
  ## Yields the nazo puyo url with all the given conditions.
  var conditions = newSeqOfCap[string](5)
  if kinds.len > 0:
    conditions.add '(' & kinds.deduplicate(true).mapIt(&"{KindColName} = {it.ord}").join(" OR ") & ')'
  if moveNums.len > 0:
    conditions.add '(' & moveNums.deduplicate(true).mapIt(&"{MoveNumColName} = {it}").join(" OR ") & ')'
  if saturates.len > 0:
    conditions.add '(' & saturates.deduplicate(true).mapIt(&"{SaturateColName} = {it.int}").join(" OR ") & ')'
  if timeIntervals.len > 0:
    let strs = collect:
      for interval in timeIntervals:
        var intervalStrs = newSeqOfCap[string](2)
        if interval.start.isSome:
          intervalStrs.add &"{TimeColName} >= '{interval.start.get.utc}'"
        if interval.stop.isSome:
          intervalStrs.add &"{TimeColName} <= '{interval.stop.get.utc}'"
        '(' & intervalStrs.join(" AND ") & ')'
    conditions.add '(' & strs.join(" OR ") & ')'
  let
    condition = conditions.join " AND "
    wherePhrase = if conditions.len == 0: "" else: &"WHERE {condition}"

  for row in db.iterate &"SELECT {UrlColName} FROM {TableName} {wherePhrase}":
    yield row[0].strVal
