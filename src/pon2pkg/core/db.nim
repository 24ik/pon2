## This module implements the database.
## Not available on JS backend.
##

import deques
import json
import hashes
import options
import sequtils
import std/appdirs
import std/dirs
import std/files
import std/paths
import strformat
import strutils
import sugar
import tables
import times
import uri

import nazopuyo_core
import puyo_core

type
  NazoPuyoProperties* = tuple
    ## Nazo puyo data with some properties.
    answers: seq[Positions]
    registerTime: Time

  RawNazoPuyoProperties = ref object
    ## Nazo puyo data with some properties, using compatible type with JSON format.
    answers: seq[string]
    registerTime: string

  NazoPuyoDatabase* = Table[NazoPuyo, NazoPuyoProperties]

# ------------------------------------------------
# Hash
# ------------------------------------------------

func hash*(field: Field): Hash {.inline.} =
  ## Returns the hash.
  field.toArray.hash

func hash*(env: Environment): Hash {.inline.} =
  ## Returns the hash.
  !$ (env.field.hash !& env.pairs.toSeq.hash)

# ------------------------------------------------
# Save / Load
# ------------------------------------------------

proc loadDatabase*(file = getDataDir() / "pon2".Path / "nazo.json".Path): NazoPuyoDatabase {.inline.} =
  ## Loads the nazo puyo database.
  if not file.fileExists:
    return

  return collect:
    for questionUri, propertiesNode in file.string.parseFile.pairs:
      let properties = propertiesNode.to RawNazoPuyoProperties

      {questionUri.parseUri.toNazoPuyo.get.nazoPuyo: (
        properties.answers.mapIt it.toPositions(IZUMIYA).get,
        properties.registerTime.parseTime("yyyy-MM-dd'T'HH:mm:sszzz", utc()))}

proc saveDatabase*(
  nazoPuyoDatabase: NazoPuyoDatabase, file = getDataDir() / "pon2".Path / "nazo.json".Path
) {.inline.} =
  ## Saves the database to the file.
  let rawTable = collect:
    for nazo, properties in nazoPuyoDatabase.pairs:
      {$nazo.toUri: {
        "answers": % properties.answers.mapIt(it.toUriQueryValue IZUMIYA),
        "registerTime": % $properties.registerTime}.toTable
      }

  var content: string
  content.toUgly %*rawTable
  file.parentDir.createDir
  file.string.writeFile content

# ------------------------------------------------
# Operation
# ------------------------------------------------

proc add*(nazoPuyoDatabase: var NazoPuyoDatabase, nazo: NazoPuyo, answers: seq[Positions] = @[]) {.inline.} =
  ## Inserts the nazo puyo and answers (optional) into the database.
  nazoPuyoDatabase[nazo] = (answers, now().utc.toTime)

iterator find*(
  nazoPuyoDatabase: NazoPuyoDatabase,
  kinds = none seq[RequirementKind],
  moveCounts = none seq[Positive],
  registerTimeIntervals = none seq[tuple[start: Option[Time], stop: Option[Time]]],
): tuple[nazoPuyo: NazoPuyo, answers: seq[Positions]] {.inline.} =
  ## Yields all nazo puyoes that satisfy the query.
  for nazo, properties in nazoPuyoDatabase.pairs:
    if kinds.isSome and nazo.requirement.kind notin kinds.get:
      continue

    if moveCounts.isSome and nazo.moveCount notin moveCounts.get:
      continue

    if registerTimeIntervals.isSome and registerTimeIntervals.get.allIt(
      (it.start.isSome and it.start.get > properties.registerTime) or
      (it.stop.isSome and it.stop.get < properties.registerTime)
    ):
      continue

    yield (nazo, properties.answers)
