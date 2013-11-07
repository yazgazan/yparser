
BnfParser = require './BnfParser'
GrammarParser = require './GrammarParser'

class Generator extends BnfParser
  constructor: (bnf) ->
    super bnf

  generate: ->
    @generateListRules()
    return new GrammarParser @tokenRules, @rules

  generateListRules: ->
    @tokenRules = {}
    @rules = {}
    for node in @ast.nodes
      if node.type is "rule"
        @rules[node.name] = node.nodes[0]
      if node.type is "tokenRule"
        @tokenRules[node.name] = node.nodes[0]

module.exports = Generator

