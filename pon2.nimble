# Package

version       = "0.5.4"
author        = "Keisuke Izumiya"
description   = "Nazo Puyo Tool"
license       = "Apache-2.0 OR MPL-2.0"

srcDir        = "src"
installExt    = @["nim"]
bin           = @["pon2"]


# Dependencies

requires "nim ^= 2.0.0"

requires "nigui ^= 0.2.7"
requires "https://github.com/hoijui/docopt.nim#3e8130e"
requires "https://github.com/izumiya-keisuke/nazopuyo-core ^= 0.10.2"
requires "https://github.com/izumiya-keisuke/puyo-core ^= 0.15.3"
requires "https://github.com/izumiya-keisuke/puyo-simulator ^= 0.11.7"
requires "https://github.com/karaxnim/karax#7dd0c83"


# Tasks

import strformat

task test, "Run Tests":
  const
    avx2 {.booldefine.} = true
    bmi2 {.booldefine.} = true

  exec &"nimble -y install -d -p:\"-d:avx2={avx2}\" -p:\"-d:bmi2={bmi2}\""

  exec &"nimble -d:avx2={avx2} -d:bmi2={bmi2} documentation"
  rmDir "src/htmldocs"

  exec &"nimble -y build -d:avx2={avx2} -d:bmi2={bmi2}"

  if buildOS != "windows": # HACK: now we cannot pass the test on Windows due to Nim's bug
    exec &"nim c -r -d:avx2={avx2} -d:bmi2={bmi2} tests/makeTest.nim"
    exec "testament all"

task documentation, "Make Documentation":
  const
    avx2 {.booldefine.} = true
    bmi2 {.booldefine.} = true

  exec &"nimble -y install -d -p:\"-d:avx2={avx2}\" -p:\"-d:bmi2={bmi2}\""

  exec &"nim doc --project --index -d:avx2={avx2} -d:bmi2={bmi2} src/pon2.nim"

task web, "Make Web Page":
  const
    avx2 {.booldefine.} = true
    bmi2 {.booldefine.} = true
    danger {.booldefine.} = true

  exec &"nimble -y install -d -p:\"-d:avx2={avx2}\" -p:\"-d:bmi2={bmi2}\""

  exec &"nim js -d:danger={danger} -o:www/index.js src/pon2.nim"
  exec "npx --yes google-closure-compiler -W QUIET --js www/index.js --js_output_file www/index.min.js"
  exec &"nim js -d:danger={danger} -o:www/worker.js src/pon2pkg/web/worker.nim"
  exec "npx --yes google-closure-compiler -W QUIET --js www/worker.js --js_output_file www/worker.min.js"

  exec "cp -r assets www"