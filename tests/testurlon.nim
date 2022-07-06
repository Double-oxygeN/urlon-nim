discard """
  action: "run"
  targets: "c js"
"""

from unittest import check
from json import `%`, `$`, `==`
import urlon

type
  Obj1 = object
    val1: string
    val2: int
    val3: bool

  Obj2 = object
    o1: Obj1
    o2: Obj1
    val1: seq[int]

  EmptyObject = object

let testcases = {
  # boolean
  %true: ":true",
  %false: ":false",

  # integer
  %0: ":0",
  %42: ":42",
  %(-1_000_000_000): ":-1000000000",

  # float
  %0.0: ":0.0",
  %3.14159: ":3.14159",
  %NaN: "=nan",
  %Inf: "=inf",
  %(-Inf): "=-inf",

  # string
  %"": "=",
  %" ": "=%20",
  %"Hello": "=Hello",
  %"你好😍": "=%E4%BD%A0%E5%A5%BD%F0%9F%98%8D",
  %"`~!@#$%^&*()_+-={}|[]\\:\";'<>?,./": "=%60~!@#$%25%5E/&*()_+-=%7B%7D%7C%5B%5D%5C:%22/;'%3C%3E?,.//",

  # array
  %[]: "@",
  %[0]: "@:0",
  %[[0]]: "@@:0",
  %[[[[0]]]]: "@@@@:0",
  %[@[[0], [0]], @[[0]]]: "@@@:0;&@:0;;&@@:0",

  # object
  %EmptyObject(): "$",
  %Obj1(val1: "obj1", val2: -1, val3: true): "$val1=obj1&val2:-1&val3:true",
  %Obj2(o1: Obj1(val1: "obj1", val2: 2, val3: false), o2: Obj1(), val1: @[1, 1, 2, 3, 5, 8, 13]): "$o1$val1=obj1&val2:2&val3:false;&o2$val1=&val2:0&val3:false;&val1@:1&:1&:2&:3&:5&:8&:13"
  }

for (jsonObj, risonStr) in testcases:
  check jsonObj.toUrlon() == risonStr
  check risonStr.parseUrlon() == jsonObj
