
YParser = require './YParser'

class DefaultHooks extends YParser
  constructor: -> super()

  cleanStr: (s) ->
    ret = ""
    tmp = s[1...-1]
    i = 0
    while i < tmp.length
      if tmp[i] is '\\'
        ret += tmp[i + 1]
        i += 2
        continue
      ret += tmp[i]
      ++i
    return ret

  upper: (s) -> s.toUpperCase()

  lower: (s) -> s.toLowerCase()

  toNumber: (s) -> +s

  debug: (ast) ->
    console.log JSON.stringify ast, null, 2
    return true

  printAst: (ast) ->
    console.log JSON.stringify @ast, null, 2
    return true

  printCurrentToken: (ast) ->
    console.log JSON.stringify @curToken, null, 2
    console.log JSON.stringify @tokens.length, null, 2
    console.log JSON.stringify @tokens[@curToken], null, 2
    return true

module.exports = DefaultHooks

