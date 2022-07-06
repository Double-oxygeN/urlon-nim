discard """
  action: "run"
  targets: "c js"
"""

from unittest import expect, fail, checkpoint
import urlon

const illegalUrlons = [
  "",
  "A",
  "@A",
  "$A",
  "$AA",
  "$A@A"
  ]

for item in illegalUrlons:
  expect UrlonParsingError:
    discard parseUrlon(item)
