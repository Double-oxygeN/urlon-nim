import json

func toUrlon*(obj: JsonNode): string =
  ## Convert JSON to URLON.
  discard

template `%%*`*(x: untyped): string =
  ## Convert any object to URLON.
  ## This uses ``json.`%*` ``.
  toUrlon(%*x)

func parseUrlon*(x: string): JsonNode =
  ## Parse URLON and convert to JSON.
  result = newJObject()

export json.to
