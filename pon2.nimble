# Package

version       = "0.7.0"
author        = "Keisuke Izumiya"
description   = "Nazo Puyo Tool"
license       = "Apache-2.0 OR MPL-2.0"

srcDir        = "src"
installExt    = @["nim"]
bin           = @["pon2"]


# Dependencies

requires "nim ^= 2.0.0"

requires "docopt ^= 0.7.1"
requires "nigui ^= 0.2.7"
requires "https://github.com/de-odex/suru#f6f1e60"
requires "https://github.com/karaxnim/karax#ca6528d"

# Tasks

import strformat

task test, "Run Tests":
  const
    avx2 {.booldefine.} = true
    bmi2 {.booldefine.} = true

  exec &"nim c -r -d:avx2={avx2} -d:bmi2={bmi2} tests/makeTest.nim"
  exec "testament all"

task documentation, "Make Documentation":
  exec &"nim doc --project src/pon2.nim"

task web, "Make Web Page":
  const danger {.booldefine.} = true

  exec &"nim js -d:danger={danger} -o:www/index.js src/pon2.nim"
  exec "npx --yes google-closure-compiler -W QUIET --js www/index.js --js_output_file www/index.min.js"
  exec &"nim js -d:danger={danger} -o:www/worker.js src/pon2pkg/web/worker.nim"
  exec "npx --yes google-closure-compiler -W QUIET --js www/worker.js --js_output_file www/worker.min.js"

  exec "cp -r assets www"