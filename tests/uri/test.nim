{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/private/[uri]

block: # updatedQuery
  let query = "foo=1&bar=2"

  check query.updatedQuery("foo", "3") == "foo=3&bar=2"
  check query.updatedQuery("baz", "3") == "foo=1&bar=2&baz=3"
  check query.updatedQuery("foo", "") == "foo&bar=2"
  check query.updatedQuery("foo", "", removeEmptyVal = true) == "bar=2"
  check query.updatedQuery("baz", "") == "foo=1&bar=2&baz"
  check query.updatedQuery("baz", "", removeEmptyVal = true) == "foo=1&bar=2"
