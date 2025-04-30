## This module implements [Puyo Puyo](https://puyo.sega.jp/) and
## [Nazo Puyo](https://vc.sega.jp/3ds/nazopuyo/).
##
## Submodule Documentations:
## - [cell](./core/cell.html)
## - [common](./core/common.html)
## - [field](./core/field.html)
## - [fqdn](./core/fqdn.html)
## - [goal](./core/goal.html)
## - [mark](./core/mark.html)
## - [moveresult](./core/moveresult.html)
## - [nazopuyo](./core/nazopuyo.html)
## - [notice](./core/notice.html)
## - [pair](./core/pair.html)
## - [placement](./core/placement.html)
## - [popresult](./core/popresult.html)
## - [puyopuyo](./core/puyopuyo.html)
## - [rule](./core/rule.html)
## - [step](./core/step.html)
##
## Compile Options:
## | Option                            | Description                            | Default          |
## | --------------------------------- | -------------------------------------- | ---------------- |
## | `-d:pon2.waterheight=<int>`       | Height of the water.                   | `8`              |
## | `-d:pon2.fqdn=<str>`              | FQDN of the web IDE.                   | `24ik.github.io` |
## | `-d:pon2.garbagerate.tsu=<int>`   | Garbage rate in Tsu rule.              | `70`             |
## | `-d:pon2.garbagerate.water=<int>` | Garbage rate in Water rule.            | `90`             |
## | `-d:pon2.simd=<int>`              | SIMD level. (1: SSE4.2, 0: None)       | 1                |
## | `-d:pon2.bmi=<int>`               | BMI level. (2: BMI2, 1: BMI1, 0: None) | 2                |
## | `-d:pon2.clmul=<bool>`            | Uses CLMUL.                            | `true`           |
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import
  ./core/[
    cell, common, field, fqdn, goal, mark, moveresult, nazopuyo, notice, pair,
    placement, popresult, puyopuyo, rule, step,
  ]

export
  cell, common, field, fqdn, goal, mark, moveresult, nazopuyo, notice, pair, placement,
  popresult, puyopuyo, rule, step
