## This module implements simulator views.
##
## Submodule Documentations:
## - [ctrl](./simulator/ctrl.html)
## - [field](./simulator/field.html)
## - [goal](./simulator/goal.html)
## - [msg](./simulator/msg.html)
## - [next](./simulator/next.html)
## - [operating](./simulator/operating.html)
## - [palette](./simulator/palette.html)
## - [setting](./simulator/setting.html)
## - [share](./simulator/share.html)
## - [simulator](./simulator/simulator.html)
## - [step](./simulator/step.html)
##
## Compile Options:
## | Option                 | Description       | Default    |
## | ---------------------- | ----------------- | ---------- |
## | `-d:pon2.assets=<str>` | Assets directory. | `./assets` |
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import
  ./simulator/
    [ctrl, field, goal, msg, next, operating, palette, setting, share, simulator, step]

export ctrl, field, goal, msg, next, operating, palette, setting, share, simulator, step
