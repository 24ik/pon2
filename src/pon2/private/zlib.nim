## This module implements zlib algorithms.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[asyncjs, base64, jsffi]
import ../[utils]

export asyncjs, utils

const EmptyBytesCompressed = "eJwDAAAAAAE="

# ------------------------------------------------
# seq[byte] <-> Uint8Array
# ------------------------------------------------

func toUint8Array(
  bytes: seq[byte]
): JsObject {.inline, noinit, importjs: "new Uint8Array(#)".}
  ## Returns the uint8 array converted from the bytes.

func toBytes(
  uint8Array: JsObject
): seq[byte] {.inline, noinit, importjs: "Array.from(#)".}
  ## Returns the bytes converted from the uint8 array.

# ------------------------------------------------
# Compress
# ------------------------------------------------

func zlibCompressed(
  uint8Array: JsObject
): Future[JsObject] {.
  inline,
  noinit,
  importjs:
    """
(async (data) => {
  const stream = new Blob([data.buffer]).stream().pipeThrough(new CompressionStream('deflate'));
  const chunks = [];
  try {
    await stream.pipeTo(new WritableStream({ write(chunk) { chunks.push(chunk); } }));
  } catch (error) {
    return new Uint8Array([]);
  }
  return new Uint8Array(await new Blob(chunks).arrayBuffer());
})(#)"""
.}
  ## Returns the compressed uint8 array with the zlib algorithm.
  ## If the compression fails, returns an empty array.

{.push warning[Uninit]: off.}
proc zlibCompressed*(
    bytes: seq[byte]
): Future[Pon2Result[string]] {.inline, noinit, async.} =
  ## Returns a string obtained by compressing the bytes with the zlib algorithm.
  if bytes.len == 0:
    return Pon2Result[string].ok EmptyBytesCompressed

  let compressedArray = await bytes.toUint8Array.zlibCompressed
  if compressedArray.length.to(int) == 0:
    return Pon2Result[string].err "zlib compression failed"

  return Pon2Result[string].ok compressedArray.toBytes.encode(safe = true)

{.pop.}

# ------------------------------------------------
# Decompress
# ------------------------------------------------

func toBytes(str: string): seq[byte] {.inline, noinit.} =
  ## Returns the bytes converted from the string.
  @(str.toOpenArrayByte(0, str.high))

func zlibDecompressed(
  uint8Array: JsObject
): Future[JsObject] {.
  inline,
  noinit,
  importjs:
    """
(async (data) => {
  const stream = new Blob([data.buffer]).stream().pipeThrough(new DecompressionStream('deflate'));
  const chunks = [];
  try {
    await stream.pipeTo(new WritableStream({ write(chunk) { chunks.push(chunk); } }));
  } catch (error) {
    return new Uint8Array([]);
  }
  return new Uint8Array(await new Blob(chunks).arrayBuffer());
})(#)"""
.}
  ## Returns the decompressed uint8 array with the zlib algorithm.
  ## If the decompression fails, returns an empty array.

proc zlibDecompressed*(
    str: string
): Future[Pon2Result[seq[byte]]] {.inline, noinit, async.} =
  ## Returns bytes obtained by compressing the string with the zlib algorithm.
  # failed decompression returns an empty array, so we need to branch here
  if str == EmptyBytesCompressed:
    return Pon2Result[seq[byte]].ok @[]

  let decodedStr: string
  try:
    decodedStr = str.decode
  except ValueError as ex:
    decodedStr = ""
    return Pon2Result[seq[byte]].err ex.msg

  let decompressedArray = await decodedStr.toBytes.toUint8Array.zlibDecompressed
  if decompressedArray.length.to(int) == 0:
    return Pon2Result[seq[byte]].err "zlib decompression failed"

  return Pon2Result[seq[byte]].ok decompressedArray.toBytes
