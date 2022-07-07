import json
from strutils import toHex, removeSuffix, join, Digits, allCharsInSet, parseBiggestInt, parseFloat
from sequtils import map
from tables import pairs
when defined(js):
  from sequtils import toSeq
  from dom import encodeURI, decodeURI
  from jsre import replace, newRegExp

else:
  from uri import decodeUrl

type
  UrlonParsingError* = object of ValueError

const urlValidChars = {
  '0'..'9', 'a'..'z', 'A'..'Z',
  ',', '?', ':', '@', '=', '+', '$',
  '-', '_', '.', '!', '~', '*', '\'',
  '(', ')', '#', '&', ';', '/'}

const
  stringPrefix = '='
  keywordOrNumberPrefix = ':'
  arrayPrefix = '@'
  objectPrefix = when defined(legacyUrlon): '_' else: '$'
  itemSeparator = '&'
  collectionSuffix = ';'
  escape = '/'

  endOfValue = {itemSeparator, collectionSuffix}
  endOfKey = {stringPrefix, keywordOrNumberPrefix, arrayPrefix, objectPrefix}

  valueEscapeTargets = endOfValue + {escape}
  keyEscapeTargets = endOfKey + {escape}

func encodeUrlWithEscapeSequence(s: string; escapeTargets: static set[char]): string =
  when defined(js):
    let escapeTargetRegExp = newRegExp("([" & toSeq(items(escapeTargets)).join() & "])", "g")
    result = $encodeURI(s.replace(escapeTargetRegExp, escape & "$1"))

  else:
    result = newStringOfCap(s.len + s.len shr 2)
    for c in s:
      case c
      of escapeTargets:
        result.add $escape & c
      of urlValidChars - escapeTargets:
        result.add c
      else:
        result.add "%"
        result.add toHex(ord(c), 2)

func decodeUrlon(s: string): string =
  when defined(js):
    result = $decodeURI(s)

  else:
    result = decodeUrl(s, decodePlus = false)

func trimTrailingCollectionSuffices(s: string): string =
  result = s
  result.removeSuffix(collectionSuffix)

func toUrlonImpl(obj: JsonNode): string =
  case obj.kind
  of JNull:
    return ":null"

  of JBool:
    return if obj.bval: ":true" else: ":false"

  of JInt:
    return keywordOrNumberPrefix & $obj.num

  of JFloat:
    return keywordOrNumberPrefix & $obj.fnum

  of JString:
    return stringPrefix & encodeUrlWithEscapeSequence(obj.str, valueEscapeTargets)

  of JArray:
    return arrayPrefix & obj.elems.map(toUrlonImpl).join($itemSeparator) & collectionSuffix

  of JObject:
    var elemUrlons: seq[string]
    for key, val in obj.fields:
      elemUrlons.add(encodeUrlWithEscapeSequence(key, keyEscapeTargets) & toUrlonImpl(val))
    return objectPrefix & elemUrlons.join($itemSeparator) & collectionSuffix

func toUrlon*(obj: JsonNode): string =
  ## Convert JSON to URLON.
  toUrlonImpl(obj).trimTrailingCollectionSuffices()

template `%%*`*(x: untyped): string =
  ## Construct an URLON.
  ## This uses ``json.`%*` ``.
  toUrlon(%*x)

template `%%`*(x: untyped): string =
  ## Convert any object to URLON.
  ## This uses ``json.`%` ``.
  toUrlon(%x)

func readToken(x: string; endOfToken: static set[char]): tuple[token: string, rest: string] =
  var pos = 0.Natural
  while pos < x.len:
    case x[pos]
    of escape:
      if succ(pos) >= x.len:
        result.token.add collectionSuffix
        return

      result.token.add x[succ(pos)]
      inc pos, 2

    of endOfToken:
      result.rest = x[pos..^1]
      return

    else:
      result.token.add x[pos]
      inc pos

func parseUrlonImpl(x: string): tuple[parsed: JsonNode, rest: string] =
  if x.len == 0:
    raise UrlonParsingError.newException("Empty string cannot be an URLON.")

  case x[0]
  of stringPrefix:
    let (token, rest) = readToken(x[1..^1], endOfValue)
    return (parsed: newJString(token), rest: rest)

  of keywordOrNumberPrefix:
    let (token, rest) = readToken(x[1..^1], endOfValue)
    if token == "true":
      return (parsed: newJBool(true), rest: rest)
    elif token == "false":
      return (parsed: newJBool(false), rest: rest)
    elif token.allCharsInSet(Digits + {'-'}):
      return (parsed: newJInt(parseBiggestInt(token)), rest: rest)
    elif token.allCharsInSet(Digits + {'-', '.'}):
      return (parsed: newJFloat(parseFloat(token)), rest: rest)
    else:
      return (parsed: newJNull(), rest: rest)

  of arrayPrefix:
    result.parsed = newJArray()

    if x.len == 1:
      return

    elif x[1] == collectionSuffix:
      result.rest = x[2..^1]
      return

    var (parsed, rest) = parseUrlonImpl(x[1..^1])
    while rest.len > 0 and rest[0] != collectionSuffix:
      result.parsed.add parsed
      assert rest[0] == itemSeparator
      (parsed, rest) = parseUrlonImpl(rest[1..^1])

    result.parsed.add parsed
    if rest.len > 1:
      assert rest[0] == collectionSuffix
      result.rest = rest[1..^1]
    return

  of objectPrefix:
    result.parsed = newJObject()

    if x.len == 1:
      return

    elif x[1] == collectionSuffix:
      result.rest = x[2..^1]
      return

    var
      (key, intermediate) = readToken(x[1..^1], endOfKey)
      (val, rest) = parseUrlonImpl(intermediate)
    while rest.len > 0 and rest[0] != collectionSuffix:
      result.parsed[key] = val
      assert rest[0] == itemSeparator
      (key, intermediate) = readToken(rest[1..^1], endOfKey)
      (val, rest) = parseUrlonImpl(intermediate)

    result.parsed[key] = val
    if rest.len > 1:
      assert rest[0] == collectionSuffix
      result.rest = rest[1..^1]
    return

  else:
    raise UrlonParsingError.newException("'" & x & "' cannot parse as URLON.")

func parseUrlon*(x: string): JsonNode =
  ## Parse URLON and convert to JSON.
  let (parsedJson, rest) = parseUrlonImpl(decodeUrlon(x))
  assert rest.len == 0
  return parsedJson

export json.to
