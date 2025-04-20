{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[appdirs, dirs, os, osproc, paths, random, sequtils, strformat, strutils]
import unittest2

const
  SimdLvl {.define: "pon2.testsimd".} = 2
  BmiLvl {.define: "pon2.testbmi".} = 2
  ClmulUse {.define: "pon2.testclmul".} = true
  TestLower {.define: "pon2.testlower".} = true # Tests lower levels

static:
  doAssert SimdLvl in 0 .. 2
  doAssert BmiLvl in 0 .. 2

type Backend {.pure.} = enum
  ## Compile backend.
  C = "c"
  Cpp = "cpp"
  Js = "js"

proc nimCacheDir(): Path =
  ## Returns a cache directory used by running.
  appdirs.getCacheDir() / "nim".Path / "pon2-test".Path / ($rand(uint64)).Path

proc outDir(file: Path, backend: Backend, simdLvl, bmiLvl: int, clmulUse: bool): Path =
  ## Returns the output directory used by running.
  appdirs.getTempDir() / "pon2".Path / "test".Path / ($backend).Path /
    file.parentDir.splitFile.name /
    "simd{simdLvl}bmi{bmiLvl}clmul{($clmulUse)[0].toUpperAscii}".fmt.Path

func filePath(testDir: Path): Path =
  ## Returns the path of the entry file.
  testDir / "test.nim".Path

proc run(file: Path, backend: Backend, simdLvl, bmiLvl: int, clmulUse: bool): string =
  ## Runs the test file and returns the output.
  let
    cacheDir = nimCacheDir()
    output =
      "nim {backend} --nimcache:{cacheDir} -w:off --hints:off -d:pon2.simd={simdLvl} -d:pon2.bmi={bmiLvl} -d:pon2.clmul={clmulUse} -r --outdir:{outDir(file, backend, simdLvl, bmiLvl, clmulUse)} {file}".fmt.execCmdEx.output

  cacheDir.removeDir

  output

template tests(
    testDirs: seq[Path], backend: Backend, simdLvl, bmiLvl: int, clmulUse: bool
): untyped =
  ## Runs tests of all modules.
  for testDir in testDirs:
    test $testDir.splitFile.name:
      check:
        testDir.filePath.run(backend, simdLvl, bmiLvl, clmulUse) == ""

func suiteName(backend: Backend, simdLvl, bmiLvl: int, clmulUse: bool): string =
  ## Returns the suite's name.
  "{backend} simd={simdLvl} bmi={bmiLvl} clmul={clmulUse}".fmt

template suites(backend: Backend): untyped =
  ## Runs the suites of specified implementation levels.
  let
    testDirs = currentSourcePath().Path.parentDir.walkDir.toSeq
    .filterIt(it.kind in {pcDir, pcLinkToDir}).mapIt it.path

    simdLvlMax = if backend == Js: 0 else: SimdLvl
    bmiLvlMax = if backend == Js: 0 else: BmiLvl
    clmulUseMax = if backend == Js: false else: ClmulUse

    simdLvls = (if TestLower: 0 else: simdLvlMax) .. simdLvlMax
    bmiLvls = (if TestLower: 0 else: bmiLvlMax) .. bmiLvlMax
    clmulUses = (if TestLower: false else: clmulUseMax) .. clmulUseMax

  for simdLvl in simdLvls:
    for bmiLvl in bmiLvls:
      for clmulUse in clmulUses:
        suite suiteName(backend, simdLvl, bmiLvl, clmulUse):
          tests testDirs, backend, simdLvl, bmiLvl, clmulUse

randomize()
suites C
suites Cpp
suites Js
