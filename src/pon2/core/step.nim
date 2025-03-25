## This module implements steps.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[bitops, math, sequtils, strformat, strutils, sugar, tables]
import results
import ./[cell, common, fqdn, pair, placement]
import ../private/[misc]

type
  StepKind* {.pure.} = enum
    ## Discriminator for `Step`.
    PutPair
    GarbageDrop

  Step* = object ## Game step.
    case kind: StepKind
    of PutPair:
      pair*: Pair
      optPlacement*: Opt[Placement]
    of GarbageDrop:
      garbageCnts*: array[Col, int]

  Steps* = seq[Step] ## Sequence of steps.

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type Step, pair: Pair, optPlacement: Opt[Placement]): T {.inline.} =
  T(kind: PutPair, pair: pair, optPlacement: optPlacement)

func init*(T: type Step, pair: Pair): T {.inline.} =
  T.init(pair, NonePlacement)

func init*(T: type Step, pair: Pair, placement: Placement): T {.inline.} =
  T.init(pair, Opt[Placement].ok placement)

func init*(T: type Step, garbageCnts: array[Col, int]): T {.inline.} =
  T(kind: GarbageDrop, garbageCnts: garbageCnts)

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `==`*(step1, step2: Step): bool {.inline.} =
  case step1.kind
  of PutPair:
    step2.kind == PutPair and step1.pair == step2.pair and
      step1.optPlacement == step2.optPlacement
  of GarbageDrop:
    step2.kind == GarbageDrop and step1.garbageCnts == step2.garbageCnts

# ------------------------------------------------
# Property
# ------------------------------------------------

func isValid*(self: Step, originalCompatible = false): bool {.inline.} =
  ## Returns `true` if the step is valid.
  case self.kind
  of PutPair:
    true
  of GarbageDrop:
    if originalCompatible:
      let
        maxCnt = self.garbageCnts.max
        minCnt = self.garbageCnts.min

      0 <= minCnt and maxCnt <= 5 and maxCnt - minCnt <= 1
    else:
      self.garbageCnts.min >= 0

# ------------------------------------------------
# Count
# ------------------------------------------------

func cellCnt*(self: Step, cell: Cell): int {.inline.} =
  ## Returns the number of `cell` in the step.
  case self.kind
  of PutPair:
    self.pair.cellCnt cell
  of GarbageDrop:
    if cell == Garbage: self.garbageCnts.sum2 else: 0

func cellCnt*(self: Step): int {.inline.} =
  ## Returns the number of `cell` in the step.
  case self.kind
  of PutPair: 2
  of GarbageDrop: self.garbageCnts.sum2

func colorCnt*(self: Step): int {.inline.} =
  ## Returns the number of color puyos in the step.
  case self.kind
  of PutPair: 2
  of GarbageDrop: 0

func garbageCnt*(self: Step): int {.inline.} =
  ## Returns the number of garbage puyos in the step.
  case self.kind
  of PutPair: 0
  of GarbageDrop: self.garbageCnts.sum2

func cellCnt*(steps: Steps, cell: Cell): int {.inline.} =
  ## Returns the number of `cell` in the steps.
  sum2 steps.mapIt it.cellCnt cell

func cellCnt*(steps: Steps): int {.inline.} =
  ## Returns the number of cells in the steps.
  sum2 steps.mapIt it.cellCnt

func colorCnt*(steps: Steps): int {.inline.} =
  ## Returns the number of color puyos in the steps.
  sum2 steps.mapIt it.colorCnt

func garbageCnt*(steps: Steps): int {.inline.} =
  ## Returns the number of garbage puyos in the steps.
  sum2 steps.mapIt it.garbageCnt

# ------------------------------------------------
# Step <-> string
# ------------------------------------------------

const
  PairPlcmtSep = '|'
  GarbagePrefix = '('
  GarbageSuffix = ')'
  GarbageSep = ","

func `$`*(self: Step): string {.inline.} =
  case self.kind
  of PutPair:
    "{self.pair}{PairPlcmtSep}{self.optPlacement}".fmt
  of GarbageDrop:
    let joined = self.garbageCnts.mapIt($it).join GarbageSep
    "{GarbagePrefix}{joined}{GarbageSuffix}".fmt

func parseStep*(str: string): Result[Step, string] {.inline.} =
  ## Returns the step converted from the string representation.
  if str.startsWith(GarbagePrefix) and str.endsWith(GarbageSuffix):
    let strs = str[1 ..^ 2].split GarbageSep
    if strs.len != Width:
      return Result[Step, string].err "Invalid step (garbage): {str}".fmt

    let cntReses = strs.mapIt it.parseIntRes
    if cntReses.anyIt it.isErr:
      return Result[Step, string].err "Invalid step (garbage): {str}".fmt

    return Result[Step, string].ok Step.init(
      [
        Col0: cntReses[0].value,
        cntReses[1].value,
        cntReses[2].value,
        cntReses[3].value,
        cntReses[4].value,
        cntReses[5].value,
      ]
    )

  let strs = str.split PairPlcmtSep
  if strs.len != 2:
    return Result[Step, string].err "Invalid step: {str}".fmt

  let pairRes = strs[0].parsePair
  if pairRes.isErr:
    return Result[Step, string].err "Invalid step (pair): {str}".fmt

  let plcmtRes = strs[1].parseOptPlacement
  if plcmtRes.isErr:
    return Result[Step, string].err "Invalid step (placement): {str}".fmt

  Result[Step, string].ok Step.init(pairRes.value, plcmtRes.value)

# ------------------------------------------------
# Step <-> URI
# ------------------------------------------------

const
  GarbageWrapUri = ($Garbage)[0]
  GarbageSepUri = "_"
  MaxGarbageToIshikawaUri = "aamyKW"
  IshikawaUriNumbers =
    "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-"

  IshikawaUriToMaxGarbage = collect:
    for i, uri in MaxGarbageToIshikawaUri:
      {uri: i}
  IshikawaUriToNum = collect:
    for i, uri in IshikawaUriNumbers:
      {uri: i}

func toUriQuery*(self: Step, fqdn = Pon2): Result[string, string] {.inline.} =
  ## Returns the URI query converted from the step.
  case self.kind
  of PutPair:
    Result[string, string].ok(
      "{self.pair.toUriQuery fqdn}{self.optPlacement.toUriQuery fqdn}".fmt
    )
  of GarbageDrop:
    case fqdn
    of Pon2:
      let joined = self.garbageCnts.mapIt($it).join GarbageSepUri
      Result[string, string].ok "{GarbageWrapUri}{joined}{GarbageWrapUri}".fmt
    of Ishikawa, Ips:
      if not self.isValid(originalCompatible = true):
        return Result[string, string].err(
          "Not supported step with Ishikawa/Ips format: {self}".fmt
        )

      let maxGarbageCnt = self.garbageCnts.max
      if maxGarbageCnt == 0:
        return Result[string, string].ok "a0"

      let
        diffs = self.garbageCnts.mapIt it - maxGarbageCnt + 1
        diffVal =
          sum2 (0 ..< Width).toSeq.mapIt diffs[it] * 2 ^ (Width - it - 1).Natural

      Result[string, string].ok MaxGarbageToIshikawaUri[maxGarbageCnt] &
        IshikawaUriNumbers[diffVal]

func parseStep*(query: string, fqdn: IdeFqdn): Result[Step, string] {.inline.} =
  ## Returns the step converted from the URI query.
  case fqdn
  of Pon2:
    if query.len <= 1:
      return Result[Step, string].err "Invalid step: {query}".fmt

    if query.startsWith(GarbageWrapUri) and query.endsWith(GarbageWrapUri):
      let strs = query[1 ..^ 2].split GarbageSepUri
      if strs.len != Width:
        return Result[Step, string].err "Invalid step (garbage): {query}".fmt

      let valReses = strs.mapIt it.parseIntRes
      if valReses.anyIt it.isErr:
        return Result[Step, string].err "Invalid step (garbage): {query}".fmt

      Result[Step, string].ok Step.init(
        [
          Col0: valReses[0].value,
          valReses[1].value,
          valReses[2].value,
          valReses[3].value,
          valReses[4].value,
          valReses[5].value,
        ]
      )
    elif query.len == 2:
      Result[Step, string].ok Step.init ?query.parsePair fqdn
    elif query.len == 4:
      Result[Step, string].ok Step.init(
        ?query[0 ..< 2].parsePair fqdn, ?query[2 ..< 4].parseOptPlacement fqdn
      )
    else:
      Result[Step, string].err "Invalid step: {query}".fmt
  of Ishikawa, Ips:
    if query.len != 2:
      return Result[Step, string].err "Invalid step: {query}".fmt

    let maxGarbageCntRes = IshikawaUriToMaxGarbage.getRes query[0]
    if maxGarbageCntRes.isOk:
      let numRes = IshikawaUriToNum.getRes query[1]
      if numRes.isErr:
        return Result[Step, string].err "Invalid step (garbage count): {query}".fmt

      var garbageCnts = initArrWith[Col, int](maxGarbageCntRes.value.pred)
      for col in Col:
        garbageCnts[col].inc numRes.value.testBit(Width - col.ord - 1).int

      return Result[Step, string].ok Step.init garbageCnts

    let pairRes = query[0 .. 0].parsePair fqdn
    if pairRes.isErr:
      return Result[Step, string].err "Invalid step (pair): {query}".fmt

    let optPlcmtRes = query[1 .. 1].parseOptPlacement fqdn
    if optPlcmtRes.isErr:
      return Result[Step, string].err "Invalid step (placement): {query}".fmt

    Result[Step, string].ok Step.init(pairRes.value, optPlcmtRes.value)

# ------------------------------------------------
# Steps <-> string
# ------------------------------------------------

const StepsSep = "\n"

func `$`*(self: Steps): string {.inline.} =
  let strs = collect:
    for step in self:
      $step

  strs.join StepsSep

func parseSteps*(str: string): Result[Steps, string] {.inline.} =
  ## Returns the steps converted from the string representation.
  let stepReses = str.split(StepsSep).mapIt it.parseStep
  if stepReses.allIt it.isOk:
    # NOTE: `it.value` raises compile error due to results' bug
    Result[Steps, string].ok stepReses.mapIt it.unsafeValue
  else:
    Result[Steps, string].err "Invalid step detected.\n[Arg]\n{str}\n[Errors]\n".fmt &
      stepReses.filterIt(it.isErr).mapIt(it.error).join "\n"

# ------------------------------------------------
# Steps <-> URI
# ------------------------------------------------

func toUriQuery*(self: Steps, fqdn = Pon2): Result[string, string] {.inline.} =
  ## Returns the URI query converted from the steps.
  let strReses = collect:
    for step in self:
      step.toUriQuery fqdn

  if strReses.allIt it.isOk:
    # NOTE: `it.value` raises compile error due to results' bug
    Result[string, string].ok strReses.mapIt(it.unsafeValue).join
  else:
    Result[string, string].err "Invalid step detected.\n[Arg]\n{self}\n[Errors]\n".fmt &
      strReses.filterIt(it.isErr).mapIt(it.error).join "\n"

func parseSteps*(query: string, fqdn: IdeFqdn): Result[Steps, string] {.inline.} =
  ## Returns the steps converted from the URI query.
  case fqdn
  of Pon2:
    var
      idx = 0
      steps = newSeq[Step]()
    while idx < query.len:
      if query[idx] == GarbageWrapUri:
        let garbageLastIdx = query.find(GarbageWrapUri, start = idx.succ)
        if garbageLastIdx == -1:
          return Result[Steps, string].err(
            "Invalid steps (gabrage area does not close): {query}".fmt
          )

        steps.add ?query[idx .. garbageLastIdx].parseStep fqdn
        idx = garbageLastIdx.succ
      else:
        if idx.succ(4) <= query.len:
          let stepRes = query[idx ..< idx.succ 4].parseStep fqdn
          if stepRes.isOk:
            steps.add stepRes.value
            idx.inc 4
            continue

        if idx.succ(2) > query.len:
          return Result[Steps, string].err "Invalid steps: {query}".fmt

        steps.add ?query[idx ..< idx.succ 2].parseStep fqdn
        idx.inc 2

    Result[Steps, string].ok steps
  of Ishikawa, Ips:
    if query.len mod 2 != 0:
      Result[Steps, string].err "Invalid steps: {query}".fmt
    else:
      let stepReses = collect:
        for i in countup(0, query.len.pred, 2):
          query[i .. i.succ].parseStep fqdn

      if stepReses.allIt it.isOk:
        # NOTE: `it.value` raises compile error due to results' bug
        Result[Steps, string].ok stepReses.mapIt it.unsafeValue
      else:
        Result[Steps, string].err(
          "Invalid step detected.\n[Arg]\n{query}\n[Errors]\n".fmt &
            stepReses.filterIt(it.isErr).mapIt(it.error).join "\n"
        )
