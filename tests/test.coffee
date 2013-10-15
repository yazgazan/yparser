#!/usr/bin/env coffee

anyfailed = false
_assert = require 'assert'
assert = (name, expr) ->
  try
    _assert expr
  catch e
    console.error "[FAIL] #{name}"
    anyfailed = true
    return
  console.log "[OK]   #{name}"
assert.eq = (name, expr, value) ->
  try
    _assert.equal expr, value
  catch e
    console.error "[FAIL] #{name}"
    anyfailed = true
    return
  console.log "[OK]   #{name}"

YParser = require '../yparser'

parser = new YParser.SimpleParser

console.log()
console.log "===[ test 1 ]==="

parser.loadString 'blah'

assert "peekChar 'b'", (parser.peekChar 'b')
assert "not peekChar 'c'", (not parser.peekChar 'c')

assert "readChar 'b'", (parser.readChar 'b')
assert "not readChar 'k'", (not parser.readChar 'k')

assert.eq "remaining == 'lah'", parser.remaining(), "lah"

assert "not parser.peekRange 'a', 'k'", (not parser.peekRange 'a', 'k')
assert "peekRange 'j', 'o'", (parser.peekRange 'j', 'o')

assert "readRange 'j', 'o'", (parser.readRange 'j', 'o')
assert.eq "remaining == 'ah'", parser.remaining(), "ah"

assert "not peekText 'al'", (not parser.peekText "al")
assert "peekText 'ah'", (parser.peekText "ah")
assert "not readEOF", (not parser.readEOF())

assert "readText 'ah'", (parser.readText "ah")
assert "readEOF", parser.readEOF()

console.log()
console.log "===[ test 2 ]==="

parser.loadString 'toto  tit2i   tata_42 4235'

assert "readText 'toto'", (parser.readText 'toto')
assert.eq "remaining == '  tit2i   tata_42 4235'", parser.remaining(), '  tit2i   tata_42 4235'

assert "not peekUntil 'u'", (not parser.peekUntil 'u')
assert "peekUntil 't'", (parser.peekUntil 't')

assert "readUntil 't'", (parser.readUntil 't')
assert.eq "remaining == 'tit2i   tata_42 4235'", parser.remaining(), 'tit2i   tata_42 4235'

assert "peekAny", parser.peekAny()
assert "readAny", parser.readAny()
assert.eq "remaining == 'it2i   tata_42 4235'", parser.remaining(), 'it2i   tata_42 4235'

assert "peekAlpha", parser.peekAlpha()
assert "readAlpha", parser.readAlpha()
assert.eq "remaining == 't2i   tata_42 4235'", parser.remaining(), 't2i   tata_42 4235'

assert "not peekNum", (not parser.peekNum())
assert "peekAlphaNum", parser.peekAlphaNum()

assert "readAlphaNum", parser.readAlphaNum()
assert.eq "remaining == '2i   tata_42 4235'", parser.remaining(), '2i   tata_42 4235'

assert "readNum", parser.readNum()
assert.eq "remaining == 'i   tata_42 4235'", parser.remaining(), 'i   tata_42 4235'

assert "not peekSpace", (not parser.peekSpace())
assert "readChar 'i'", (parser.readChar 'i')

assert "readSpace", parser.readSpace()
assert.eq "remaining == '  tata_42 4235'", parser.remaining(), '  tata_42 4235'

assert "not readAll 'k'", (not parser.readAll 'k')
assert "readAll ' '", (parser.readAll ' ')
assert.eq "remaining == 'tata_42 4235'", parser.remaining(), 'tata_42 4235'

assert "not readInteger", (not parser.readInteger())
assert "readIdentifier", parser.readIdentifier()

assert "readSpace", parser.readSpace()
assert.eq "remaining == '4235'", parser.remaining(), '4235'

assert "not readIdentifier", (not parser.readIdentifier())
assert "readInteger", parser.readInteger()

assert "readEOF", parser.readEOF()

console.log()
console.log "===[ test 3 ]==="

parser.loadString "blahblah ['a'|'d'|'f'|'k'..'o'] titi"

assert "readUntil '['", (parser.readUntil '[')
assert "readChar '['", (parser.readChar '[')

assert "beginCapture 'cap1'", (parser.beginCapture 'cap1')

assert "readText `'a'`", (parser.readText "'a'")
assert "readChar '|'", (parser.readChar '|')

assert "beginCapture 'cap2'", (parser.beginCapture 'cap2')

assert "not readText `'e'`", (not parser.readText "'e'")
assert "readText `'d'`", (parser.readText "'d'")

assert.eq "endCapture 'cap2' == `'d'`", (parser.endCapture 'cap2'), "'d'"

assert "readUntil ']'", (parser.readUntil ']')
assert "not endCapture 'cap3'", (not parser.endCapture 'cap3')
assert.eq "endCapture 'cap1' == `'a'|'d'|'f'|'k'..'o'`", (parser.endCapture 'cap1'), "'a'|'d'|'f'|'k'..'o'"

assert "readChar ']'", (parser.readChar ']')
assert "readSpace", parser.readSpace()
assert "readIdentifier", parser.readIdentifier()
assert "readEOF", parser.readEOF()

console.log()
console.log "===[ test 4 ]==="

parser = new YParser.ExtendedParser

grammar_id =
  type: 'or'
  repeat: '+'
  nodes: [
    {
      type: 'not'
      repeat: '1'
      nodes: [
        {
          type: 'char'
          repeat: '1'
          nodes: ['(']
        },{
          type: 'char'
          repeat: '1'
          nodes: [')']
        },{
          type: 'char'
          repeat: '1'
          nodes: ["'"]
        },{
          type: 'space'
          repeat: '1'
          nodes: []
        }
      ]
    },{
      type: 'any'
      repeat: '1'
      nodes: []
    }
  ]

grammar_str =
  type: 'and'
  repeat: '1'
  nodes: [
    {
      type: 'char'
      repeat: '1'
      nodes: ["'"]
    },{
      type: 'or'
      repeat: '*'
      nodes: [
        {
          type: 'text'
          repeat: '1'
          nodes: ["\\\\"]
        },{
          type: 'text'
          repeat: '1'
          nodes: ["\\'"]
        },{
          type: 'any'
          repeat: '1'
          nodes: []
        },{
          type: 'not'
          repeat: '1'
          nodes: [
            {
              type: 'char'
              repeat: '1'
              nodes: ["'"]
            }
          ]
        }
      ]
    },{
      type: 'char'
      repeat: '1'
      nodes: ["'"]
    }
  ]

grammar_cmd =
  type: 'and'
  repeat: '1'
  nodes: [
    {
      type: 'char'
      repeat: '1'
      nodes: ['(']
    },{
      type: 'sub'
      repeat: '1'
      cap: 'cmd_id'
      nodes: ['_id']
    },{
      type: 'and'
      repeat: '*'
      nodes: [
        {
          type: 'space'
          repeat: '+'
          nodes: []
        },{
          type: 'or'
          repeat: '1'
          nodes: [
            {
              type: 'int'
              repeat: '1'
              cap: 'cmd_arg_int'
              nodes: []
            },{
              type: 'sub'
              repeat: '1'
              cap: 'cmd_arg_id'
              nodes: ['_id']
            },{
              type: 'sub'
              repeat: '1'
              cap: 'cmd_arg_str'
              nodes: ['_str']
            },{
              type: 'sub'
              repeat: '1'
              ast: 'cmd_arg_cmd'
              nodes: ['_cmd']
            }
          ]
        }
      ]
    },{
      type: 'char'
      repeat: '1'
      nodes: [')']
    }
  ]

grammar_line =
  type: 'and'
  repeat: '*'
  nodes: [
    {
      type: 'anyspace'
      repeat: '*'
      nodes: []
    },{
      type: 'sub'
      repeat: '1'
      ast: 'cmd'
      nodes: ['_cmd']
    },{
      type: 'anyspace'
      repeat: '*'
      nodes: []
    }
  ]

parser.setGrammar '_id', grammar_id
parser.setGrammar '_str', grammar_str
parser.setGrammar '_cmd', grammar_cmd
parser.setGrammar '_line', grammar_line

console.log()
console.log "===[ test 4.1 ]==="

parser.loadString "toto"
assert "parse _id 'toto'", (parser.execGrammar '_id')

parser.loadString "'toto'"
assert "not parse _id `'toto`", (not parser.execGrammar '_id')

parser.loadString "toto_42"
assert "parse _id 'toto_42'", (parser.execGrammar '_id')

parser.loadString "toto 42"
assert "parse _id 'toto 42'", (parser.execGrammar '_id')
assert.eq "remaining == ' 42'", parser.remaining(), " 42"

parser.loadString "264"
assert "parse _id '264'", (parser.execGrammar '_id')

parser.loadString "to\"to(titi"
assert "parse _id 'to\"to(titi'", (parser.execGrammar '_id')
assert.eq "remaining == '(titi'", parser.remaining(), "(titi"

console.log()
console.log "===[ test 4.2 ]==="

parser.loadString "'toto'"
assert "parse _str `'toto'`", (parser.execGrammar '_str')

parser.loadString "'to'to'"
assert "parse _str `'to'to'`", (parser.execGrammar '_str')
assert.eq "remaining == `to'`", parser.remaining(), "to'"

parser.loadString "'to\\'to'"
assert "parse _str `'to\\'to'`", (parser.execGrammar '_str')
assert "EOF", parser.readEOF()

parser.loadString "'to\\\\'to'"
assert "parse _str `'to\\\\'to'`", (parser.execGrammar '_str')
assert.eq "remaining == `to'`", parser.remaining(), "to'"

console.log()
console.log "===[ test 4.3 ]==="

parser.loadString "(print 'titi')"
assert "parse _cmd `#{parser.buffer}`", (parser.execGrammar '_cmd')

parser.loadString "(print 42)"
assert "parse _cmd `#{parser.buffer}`", (parser.execGrammar '_cmd')

parser.loadString "(print ha)"
assert "parse _cmd `#{parser.buffer}`", (parser.execGrammar '_cmd')

parser.loadString "(print (+ 5 2))"
assert "parse _cmd `#{parser.buffer}`", (parser.execGrammar '_cmd')

parser.loadString "(print (+ 5 2) (list 1 2 3 4 5 6))"
assert "parse _cmd `#{parser.buffer}`", (parser.execGrammar '_cmd')

console.log()
console.log "===[ test 4.3 ]==="

parser.loadString "(print (+ 5 2) (list 1 2 3 4 5 6))"
assert "parse _line `#{parser.buffer}`", (parser.execGrammar '_line')

parser.loadString "(print (+ 5 2) (list 1 2 3 4 5 6))(exit)"
assert "parse _line `#{parser.buffer}`", (parser.execGrammar '_line')

parser.loadString "(print (+ 5 2) (list 1 2 3 4 5 6)) (exit)"
assert "parse _line `#{parser.buffer}`", (parser.execGrammar '_line')

parser.loadString "(+ 1 2) (- 3 4)  (exit)"
assert "parse _line `#{parser.buffer}`", (parser.execGrammar '_line')

parser.loadString "(+ 1 2)(- 3 4)\t\t\t\t  \t(exit)"
assert "parse _line `(+ 1 2)(- 3 4)\\t\\t\\t\\t  \\t(exit)`", (parser.execGrammar '_line')

parser.loadString "  (+ 1 2) (- 3 4) (exit)\t"
assert "parse _line `#{parser.buffer}`", (parser.execGrammar '_line')

parser = new YParser.AstParser

parser.setGrammar '_id', grammar_id
parser.setGrammar '_str', grammar_str
parser.setGrammar '_cmd', grammar_cmd
parser.setGrammar '_line', grammar_line

# parser.initAst new Array

parser.register 'cmd', (ast) ->
  node = new Object
  node.type = 'cmd'
  node.id = null
  node.nodes = new Array
  # node.args = new Array
  # ast.push node
  return node

parser.register 'cmd_id', (ast, cap) ->
  ast.id = cap
  return null

parser.register 'cmd_arg_int', (ast, cap) ->
  val = +cap
  node =
    type: 'int'
    value: val
  return node

parser.register 'cmd_arg_id', (ast, cap) ->
  node =
    type: 'id'
    value: cap
  return node

parser.register 'cmd_arg_str', (ast, cap) ->
  node =
    type: 'str'
    value: cap
  return node

parser.register 'cmd_arg_cmd', (ast) ->
  node = new Object
  node.type = 'cmd'
  node.id = null
  node.nodes = new Array
  return node

console.log()
console.log "===[ test 5 ]==="

parser.loadString "(print 'ha' 42)"
assert "parse _line `#{parser.buffer}`", (parser.execGrammar '_line')
res = JSON.stringify parser.ast
expected = '{"nodes":[{"type":"cmd","id":"print","nodes":[{"type":"str","value":"\'ha\'"},{"type":"int","value":42}]}]}'
assert.eq "ast", res, expected

parser.loadString "(print 'ha' 42 (+ 2 2))"
parser.initAst()
assert "parse _line `#{parser.buffer}`", (parser.execGrammar '_line')
res = JSON.stringify parser.ast
expected = '{"nodes":[{"type":"cmd","id":"print","nodes":[{"type":"str","value":"\'ha\'"},{"type":"int","value":42},{"type":"cmd","id":"+","nodes":[{"type":"int","value":2},{"type":"int","value":2}]}]}]}'
assert.eq "ast", res, expected

parser.loadString "(print 'ha' 42 (+ 2 2)) \n (exit (- last 1))"
parser.initAst()
assert "parse _line `#{parser.buffer}`", (parser.execGrammar '_line')
res = JSON.stringify parser.ast
expected = '{"nodes":[{"type":"cmd","id":"print","nodes":[{"type":"str","value":"\'ha\'"},{"type":"int","value":42},{"type":"cmd","id":"+","nodes":[{"type":"int","value":2},{"type":"int","value":2}]}]},{"type":"cmd","id":"exit","nodes":[{"type":"cmd","id":"-","nodes":[{"type":"id","value":"last"},{"type":"int","value":1}]}]}]}'
assert.eq "ast", res, expected

console.log()
console.log "===[ test 6 ]==="

parser = new YParser.GrammarParser

parser.loadString "'a'"
parser.initAst()
assert "parse rule `#{parser.buffer}`", parser.execGrammar 'rule'
res = JSON.stringify parser.ast
expected = '{"type":"and","repeat":"1","nodes":[{"type":"text","repeat":"1","ast":null,"cap":null,"nodes":["a"]}]}'
assert.eq "ast", res, expected

parser.loadString "'a' 'b'"
parser.initAst()
assert "parse rule `#{parser.buffer}`", parser.execGrammar 'rule'
res = JSON.stringify parser.ast
expected = '{"type":"and","repeat":"1","nodes":[{"type":"text","repeat":"1","ast":null,"cap":null,"nodes":["a"]},{"type":"text","repeat":"1","ast":null,"cap":null,"nodes":["b"]}]}'
assert.eq "ast", res, expected

parser.loadString "'a'|'b'"
parser.initAst()
assert "parse rule `#{parser.buffer}`", parser.execGrammar 'rule'
res = JSON.stringify parser.ast
expected = '{"type":"or","repeat":"1","nodes":[{"type":"text","repeat":"1","ast":null,"cap":null,"nodes":["a"]},{"type":"text","repeat":"1","ast":null,"cap":null,"nodes":["b"]}]}'
assert.eq "ast", res, expected

parser.loadString "num | id ^ 'd'"
parser.initAst()
assert "parse rule `#{parser.buffer}`", parser.execGrammar 'rule'
res = JSON.stringify parser.ast
expected = "{\"type\":\"or\",\"repeat\":\"1\",\"nodes\":[{\"type\":\"num\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[]},{\"type\":\"id\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[]},{\"type\":\"not\",\"repeat\":\"1\",\"cap\":null,\"ast\":null,\"nodes\":[{\"type\":\"text\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[\"d\"]}]}]}"
assert.eq "ast", res, expected

parser.loadString "num | id ^ 'd' ^ 'k'+"
parser.initAst()
assert "parse rule `#{parser.buffer}`", parser.execGrammar 'rule'
res = JSON.stringify parser.ast
expected = "{\"type\":\"or\",\"repeat\":\"1\",\"nodes\":[{\"type\":\"num\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[]},{\"type\":\"id\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[]},{\"type\":\"not\",\"repeat\":\"1\",\"cap\":null,\"ast\":null,\"nodes\":[{\"type\":\"text\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[\"d\"]}]},{\"type\":\"not\",\"repeat\":\"1\",\"cap\":null,\"ast\":null,\"nodes\":[{\"type\":\"text\",\"repeat\":\"+\",\"ast\":null,\"cap\":null,\"nodes\":[\"k\"]}]}]}"
assert.eq "ast", res, expected

parser.loadString "num | id ^['t' | 'b']"
parser.initAst()
assert "parse rule `#{parser.buffer}`", parser.execGrammar 'rule'
res = JSON.stringify parser.ast
expected = "{\"type\":\"or\",\"repeat\":\"1\",\"nodes\":[{\"type\":\"num\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[]},{\"type\":\"id\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[]},{\"type\":\"not\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[{\"type\":\"text\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[\"t\"]},{\"type\":\"text\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[\"b\"]}]}]}"
assert.eq "ast", res, expected

parser.loadString "id space+ id space+ num space+ num"
parser.initAst()
assert "parse rule `#{parser.buffer}`", parser.execGrammar 'rule'
res = JSON.stringify parser.ast
expected = "{\"type\":\"and\",\"repeat\":\"1\",\"nodes\":[{\"type\":\"id\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[]},{\"type\":\"space\",\"repeat\":\"+\",\"ast\":null,\"cap\":null,\"nodes\":[]},{\"type\":\"id\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[]},{\"type\":\"space\",\"repeat\":\"+\",\"ast\":null,\"cap\":null,\"nodes\":[]},{\"type\":\"num\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[]},{\"type\":\"space\",\"repeat\":\"+\",\"ast\":null,\"cap\":null,\"nodes\":[]},{\"type\":\"num\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[]}]}"
assert.eq "ast", res, expected

parser.loadString "id ':' num [spaces num]*"
parser.initAst()
assert "parse rule `#{parser.buffer}`", parser.execGrammar 'rule'
res = JSON.stringify parser.ast
expected = "{\"type\":\"and\",\"repeat\":\"1\",\"nodes\":[{\"type\":\"id\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[]},{\"type\":\"text\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[\":\"]},{\"type\":\"num\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[]}]}"
assert.eq "ast", res, expected

parser.loadString "line#[id:id ':' arg:num \n[space+ arg:num]* eol]+"
parser.initAst()
assert "parse rule `#{parser.buffer}`", parser.execGrammar 'rule'
res = JSON.stringify parser.ast
expected = "{\"type\":\"and\",\"repeat\":\"1\",\"nodes\":[{\"type\":\"and\",\"repeat\":\"+\",\"ast\":\"line\",\"cap\":null,\"nodes\":[{\"type\":\"id\",\"repeat\":\"1\",\"ast\":null,\"cap\":\"id\",\"nodes\":[]},{\"type\":\"text\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[\":\"]},{\"type\":\"num\",\"repeat\":\"1\",\"ast\":null,\"cap\":\"arg\",\"nodes\":[]},{\"type\":\"and\",\"repeat\":\"*\",\"ast\":null,\"cap\":null,\"nodes\":[{\"type\":\"space\",\"repeat\":\"+\",\"ast\":null,\"cap\":null,\"nodes\":[]},{\"type\":\"num\",\"repeat\":\"1\",\"ast\":null,\"cap\":\"arg\",\"nodes\":[]}]},{\"type\":\"eol\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[]}]}]}"
assert.eq "ast", res, expected

parser.loadString "toto:['a' %[eol 'b']]"
parser.initAst()
assert "parse rule `#{parser.buffer}`", parser.execGrammar 'rule'
res = JSON.stringify parser.ast
expected = "{\"type\":\"and\",\"repeat\":\"1\",\"nodes\":[{\"type\":\"and\",\"repeat\":\"1\",\"ast\":null,\"cap\":\"toto\",\"nodes\":[{\"type\":\"text\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[\"a\"]},{\"type\":\"and\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[{\"type\":\"eol\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[]},{\"type\":\"text\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[\"b\"]}],\"peek\":true}]}]}"
assert.eq "ast", res, expected

# parser.loadString "(print 'haha' 42 _toto (sub a 1))"

console.log()
console.log "===[ test 7 ]==="

parser0 = new YParser.GrammarParser

parser0.loadString "main :: toto:['a' %[eol 'b']] ;"
parser0.initAst()
parser = parser0.loadGrammar()
assert "parse main `#{parser0.buffer}`", (parser isnt false)
res = JSON.stringify parser.grammars
expected = "{\"main\":{\"type\":\"and\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[{\"type\":\"and\",\"repeat\":\"1\",\"ast\":null,\"cap\":\"toto\",\"nodes\":[{\"type\":\"text\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[\"a\"]},{\"type\":\"and\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[{\"type\":\"eol\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[]},{\"type\":\"text\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[\"b\"]}],\"peek\":true}]}]}}"
assert.eq "ast peek", res, expected
parser.loadString "a\nb"
parser.execGrammar "main"
res = JSON.stringify parser.ast
expected = "{\"nodes\":[{\"type\":\"toto\",\"nodes\":[\"a\"]}]}"
assert.eq "test peek", res, expected
assert.eq "remaining peek", parser.remaining(), "\nb"

parser1 = new YParser.GrammarParser

parser1.loadFile 'test1.bnf', ->
  @initAst()
  parser = @loadGrammar()
  assert "parse main `#{@buffer}`", (parser isnt false)
  res = JSON.stringify parser.grammars
  expected = '{"main":{"type":"and","repeat":"1","ast":null,"cap":null,"nodes":[{"type":"and","repeat":"+","ast":null,"cap":null,"nodes":[{"type":"sub","repeat":"1","ast":"line","cap":null,"nodes":["line"]}]},{"type":"eof","repeat":"1","ast":null,"cap":null,"nodes":[]}]},"line":{"type":"and","repeat":"1","ast":null,"cap":null,"nodes":[{"type":"and","repeat":"*","ast":null,"cap":null,"nodes":[{"type":"sub","repeat":"1","ast":null,"cap":"value","nodes":["content"]},{"type":"text","repeat":"1","ast":null,"cap":null,"nodes":[";"]}]},{"type":"eol","repeat":"1","ast":null,"cap":null,"nodes":[]}]},"content":{"type":"and","repeat":"1","ast":null,"cap":null,"nodes":[{"type":"or","repeat":"*","ast":null,"cap":null,"nodes":[{"type":"any","repeat":"1","ast":null,"cap":null,"nodes":[]},{"type":"not","repeat":"1","cap":null,"ast":null,"nodes":[{"type":"text","repeat":"1","ast":null,"cap":null,"nodes":[";"]}]},{"type":"not","repeat":"1","cap":null,"ast":null,"nodes":[{"type":"eol","repeat":"1","ast":null,"cap":null,"nodes":[]}]}]}]}}'
  assert.eq "ast csv", res, expected
  parser.loadFile 'test.csv', ->
    @execGrammar 'main'
    res = JSON.stringify @ast
    expected = "{\"nodes\":[{\"type\":\"line\",\"nodes\":[{\"type\":\"value\",\"nodes\":[\"toto\"]},{\"type\":\"value\",\"nodes\":[\"titi tata\"]},{\"type\":\"value\",\"nodes\":[\" 4242\"]}]},{\"type\":\"line\",\"nodes\":[{\"type\":\"value\",\"nodes\":[\"tutu\"]},{\"type\":\"value\",\"nodes\":[\" haha * \"]},{\"type\":\"value\",\"nodes\":[\" 32 55 blah\"]},{\"type\":\"value\",\"nodes\":[\"\"]},{\"type\":\"value\",\"nodes\":[\"$$$\"]}]}]}"
    assert.eq "test.csv", res, expected

parser2 = new YParser.GrammarParser
parser2.loadFile 'test2.bnf', ->
  @initAst()
  parser = @loadGrammar()
  assert "parse main `#{@buffer}`", (parser isnt false)
  res = JSON.stringify parser.grammars
  expected = "{\"main\":{\"type\":\"and\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[{\"type\":\"and\",\"repeat\":\"+\",\"ast\":null,\"cap\":null,\"nodes\":[{\"type\":\"anyspace\",\"repeat\":\"*\",\"ast\":null,\"cap\":null,\"nodes\":[]},{\"type\":\"sub\",\"repeat\":\"1\",\"ast\":\"cmd\",\"cap\":null,\"nodes\":[\"cmd\"]},{\"type\":\"anyspace\",\"repeat\":\"*\",\"ast\":null,\"cap\":null,\"nodes\":[]}]},{\"type\":\"eof\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[]}]},\"cmd\":{\"type\":\"and\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[{\"type\":\"text\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[\"(\"]},{\"type\":\"anyspace\",\"repeat\":\"*\",\"ast\":null,\"cap\":null,\"nodes\":[]},{\"type\":\"or\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[{\"type\":\"int\",\"repeat\":\"1\",\"ast\":null,\"cap\":\"repeat\",\"nodes\":[],\"capField\":true},{\"type\":\"sub\",\"repeat\":\"1\",\"ast\":null,\"cap\":\"id\",\"nodes\":[\"_id\"],\"capField\":true},{\"type\":\"str\",\"repeat\":\"1\",\"ast\":null,\"cap\":\"str!\",\"nodes\":[],\"capField\":true}]},{\"type\":\"sub\",\"repeat\":\"*\",\"ast\":null,\"cap\":null,\"nodes\":[\"arg\"]},{\"type\":\"anyspace\",\"repeat\":\"*\",\"ast\":null,\"cap\":null,\"nodes\":[]},{\"type\":\"text\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[\")\"]}]},\"arg\":{\"type\":\"and\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[{\"type\":\"anyspace\",\"repeat\":\"+\",\"ast\":null,\"cap\":null,\"nodes\":[]},{\"type\":\"or\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[{\"type\":\"int\",\"repeat\":\"1\",\"ast\":null,\"cap\":\"num\",\"nodes\":[]},{\"type\":\"sub\",\"repeat\":\"1\",\"ast\":null,\"cap\":\"id\",\"nodes\":[\"_id\"]},{\"type\":\"str\",\"repeat\":\"1\",\"ast\":null,\"cap\":\"str!\",\"nodes\":[]},{\"type\":\"sub\",\"repeat\":\"1\",\"ast\":\"cmd\",\"cap\":null,\"nodes\":[\"cmd\"]}]}]},\"_id\":{\"type\":\"and\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[{\"type\":\"or\",\"repeat\":\"+\",\"ast\":null,\"cap\":null,\"nodes\":[{\"type\":\"any\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[]},{\"type\":\"not\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[{\"type\":\"text\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[\"(\"]},{\"type\":\"text\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[\")\"]},{\"type\":\"text\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[\"\\\"\"]},{\"type\":\"anyspace\",\"repeat\":\"1\",\"ast\":null,\"cap\":null,\"nodes\":[]}]}]}]}}"
  assert.eq "ast lisp", res, expected
  parser.loadFile 'test.lisp', ->
    assert 'parse test.lisp', @execGrammar 'main'
    res = JSON.stringify @ast
    expected = "{\"nodes\":[{\"type\":\"cmd\",\"nodes\":[{\"type\":\"id\",\"nodes\":[\"blah\"]}],\"id\":\"<-\"},{\"type\":\"cmd\",\"nodes\":[{\"type\":\"num\",\"nodes\":[\"42\"]},{\"type\":\"id\",\"nodes\":[\"blah\"]},{\"type\":\"str\",\"nodes\":[\"haha\\\"\"]},{\"type\":\"id\",\"nodes\":[\"'hey\"]},{\"type\":\"cmd\",\"nodes\":[{\"type\":\"num\",\"nodes\":[\"1\"]},{\"type\":\"num\",\"nodes\":[\"2\"]}],\"id\":\"+\"}],\"id\":\"print\"},{\"type\":\"cmd\",\"nodes\":[{\"type\":\"cmd\",\"nodes\":[{\"type\":\"id\",\"nodes\":[\"blah\"]},{\"type\":\"str\",\"nodes\":[\"ha\"]}],\"id\":\"=\"},{\"type\":\"cmd\",\"nodes\":[{\"type\":\"str\",\"nodes\":[\"-l\"]},{\"type\":\"str\",\"nodes\":[\"-p\"]},{\"type\":\"num\",\"nodes\":[\"4242\"]}],\"str\":\"nc\"},{\"type\":\"cmd\",\"nodes\":[{\"type\":\"str\",\"nodes\":[\"nc\"]}],\"str\":\"man\"}],\"id\":\"if\"},{\"type\":\"cmd\",\"nodes\":[{\"type\":\"cmd\",\"nodes\":[{\"type\":\"str\",\"nodes\":[\"this will be written 42 times !\"]}],\"id\":\"print\"}],\"repeat\":\"42\"}]}"
    assert.eq "test.lisp", res, expected

console.log()

