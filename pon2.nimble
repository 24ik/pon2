# Package

version       = "0.7.0"
author        = "Keisuke Izumiya"
description   = "Puyo Puyo Library"
license       = "Apache-2.0 OR MPL-2.0"

srcDir        = "src"
installExt    = @["nim"]
bin           = @["pon2"]


# Dependencies

requires "nim ^= 2.0.0"

requires "docopt ^= 0.7.1"
requires "karax ^= 1.3.3"
requires "nigui ^= 0.2.7"
requires "nimsimd ^= 1.2.6"
requires "https://github.com/de-odex/suru#head"

# Tasks

import strformat

task test, "Run Tests":
  const
    avx2 {.intdefine.} = 2
    bmi2 {.intdefine.} = 2

  exec &"nim c -r -d:avx2={avx2} -d:bmi2={bmi2} tests/makeTest.nim"
  exec "testament all"

task benchmark, "Benchmarking":
  const
    avx2 {.booldefine.} = true
    bmi2 {.booldefine.} = true

  exec &"nim c -r -d:avx2={avx2} -d:bmi2={bmi2} benchmark/main.nim"

task documentation, "Make Documentation":
  exec &"nim doc --project -d:avx2=true src/pon2.nim" 
  mvDir "src/htmldocs", "src/htmldocs2"

  exec &"nim doc --project -d:avx2=false src/pon2.nim" 
  exec "cp -r src/htmldocs2 src/htmldocs"
  rmDir "src/htmldocs2"

task web, "Make Web Page":
  const
    danger {.booldefine.} = true
    minify {.booldefine.} = true
    verbose {.booldefine.} = false

  # main script
  exec &"nim js -d:danger={danger} -o:www/index.js src/pon2.nim"
  let cmd =
    if minify:
      "npx --yes google-closure-compiler " &
      (if verbose: "" else: "-W QUIET ") &
      "--js www/index.js --js_output_file www/index.min.js"
    else:
      "cp www/index.js www/index.min.js"
  exec cmd

  exec "cp -r assets www"