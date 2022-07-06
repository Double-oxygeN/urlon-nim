import json
from strutils import toHex, removeSuffix, join
from sequtils import map
from tables import pairs
when defined(js):
  from sequtils import toSeq
  from dom import encodeURI
  from jsre import replace, newRegExp

const urlValidChars = {
  '0'..'9', 'a'..'z', 'A'..'Z',
  ',', '?', ':', '@', '=', '+', '$',
  '-', '_', '.', '!', '~', '*', '\'',
  '(', ')', '#', '&', ';', '/'}

const
  arrayPrefix = '@'
  objectPrefix = when defined(legacyUrlon): '_' else: '$'
  itemSeparator = '&'
  collectionSuffix = ';'
  escape = '/'

  valueEscapeTargets = {itemSeparator, collectionSuffix, escape}
  keyEscapeTargets = valueEscapeTargets + {arrayPrefix, objectPrefix}

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
    return ":" & $obj.num

  of JFloat:
    return ":" & $obj.fnum

  of JString:
    return "=" & encodeUrlWithEscapeSequence(obj.str, valueEscapeTargets)

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
  ## Convert any object to URLON.
  ## This uses ``json.`%*` ``.
  toUrlon(%*x)

func parseUrlon*(x: string): JsonNode =
  ## Parse URLON and convert to JSON.
  result = newJObject()

export json.to
