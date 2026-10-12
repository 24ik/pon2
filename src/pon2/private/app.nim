## This module implements private stuff for `app`.
##
## Submodule Documentations:
## - [grimoire](./app/grimoire.html)
## - [solve](./app/solve.html)
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}
{.push raises: [].}

import ./app/[grimoire, solve]

export grimoire, solve
