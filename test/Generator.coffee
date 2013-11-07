
Generator = require '../lib/Generator'

assert = (expected, actual) ->
  if (expected isnt undefined) and (actual isnt undefined)
    if expected is actual
      return
  err = new Error
  err.expected = "" + expected
  err.actual = "" + actual
  throw err

bnf0 = """

id = id ;
spaces = spaces ;

main :: [spaces? id]+ spaces? eof
  ;

"""

bnf1 = """

id = id ;
spaces = spaces ;

main :: [spaces? id:id]+ spaces? eof
  ;

"""

bnf2 = """

id = id ;
spaces = spaces ;
PO = '(' ;
PC = ')' ;

main :: list* spaces? eof
  ;

list ::
  spaces? PO
  [spaces? id]*
  spaces? !PC
  ;

"""

bnf3 = """

id = id ;
spaces = spaces ;
PO = '(' ;
PC = ')' ;

main :: list* spaces? eof
  ;

list ::
  list#[
    spaces? PO
    spaces? .id:id?
    [spaces? id:id]*
    spaces? !PC
  ]
  ;

"""

bnf4 = """

id = id ;
int = int ;
str = '"' [['\\\\"' | any] ^ '"']* '"' ;
spaces = spaces ;
PO = '(' ;
PC = ')' ;

main :: token* spaces? eof
  ;

list ::
  PO
  .id:id?
  token*
  spaces? !PC
  ;

token::
  spaces?
  [
      list#list
    | id:id
    | int(toNumber):int
    | str(cleanStr):str
  ]
  ;

"""

bnf5 = """

id = id ;
int = int ;
str = '"' [['\\\\"' | any] ^ '"']* '"' ;
spaces = spaces ;
PO = '(' ;
PC = ')' ;
HO = '[' ;
HC = ']' ;

main :: token* spaces? eof
  ;

list ::
  PO
  .id:token?
  token*
  spaces? !PC
  ;

hash ::
  HO
  [duet#duet]*
  spaces? !HC
  ;

duet ::
  token
  !token
  ;

token::
  spaces?
  [
      list#list
    | hash#hash
    | id:id
    | int(toNumber):int
    | str(cleanStr):str
  ]
  ;

"""

bnf6 = """

id = id ;
int = int ;
str = '"' [['\\\\"' | any] ^ '"']* '"' ;
spaces = spaces ;
PO = '(' ;
PC = ')' ;
HO = '[' ;
HC = ']' ;

main :: token* spaces? eof
  ;

list ::
  PO
  .id:token?
  token*
  spaces? !PC
  ;

hash ::
  HO
  [duet#duet]*
  spaces? !HC
  ;

duet ::
  @token_key
  token
  !token
  ;

token ::
  spaces?
  [
      list#list
    | hash#hash
    | id:id
    | int(toNumber):int
    | str(cleanStr):str
  ]
  ;

token_key ::
  spaces?
  [
    .key:id
    | .key(toNumber):int
    | .key(cleanStr):str
  ]
  ;

"""

describe "Generator", ->
  describe "#constructor", ->
    it "should construct a generator, parsing the bnf", ->
      parser = new Generator bnf0
      assert true, (parser.ast.nodes.length > 0)

  describe "#generate", ->
    describe "0", ->
      test_str = "haha hihi blah test toto"
      generator = new Generator bnf0
      it "should parse the string without errors", ->
        parser = generator.generate()
        parser.loadString test_str
        parser.init()
        assert true, parser.parse()
        assert 0, parser.ast.nodes.length

    describe "1", ->
      test_str = "haha hihi blah test toto"
      res = ["haha", "hihi", "blah", "test", "toto"]
      it "should parse the string with captures", ->
        generator = new Generator bnf1
        parser = generator.generate()
        parser.loadString test_str
        parser.init()
        assert true, parser.parse()
        assert 5, parser.ast.nodes.length
        for token, id in parser.ast.nodes
          assert res[id], token.data
          assert "id", token.type

    describe "2", ->
      test_str = "(ha hi ho) (blah toto)"
      it "should parse the string with sub-rule", ->
        generator = new Generator bnf2
        parser = generator.generate()
        parser.loadString test_str
        parser.init()
        assert true, parser.parse()

    describe "3", ->
      test_str = "(ha hi ho) (blah toto)"
      expected = "{\"type\":\"root\",\"nodes\":[{\"type\":\"list\",\"nodes\":[{\"type\":\"id\",\"data\":\"hi\"},{\"type\":\"id\",\"data\":\"ho\"}],\"id\":\"ha\"},{\"type\":\"list\",\"nodes\":[{\"type\":\"id\",\"data\":\"toto\"}],\"id\":\"blah\"}]}"

      it "should build an ast tree with captures", ->
        generator = new Generator bnf3
        parser = generator.generate()
        parser.loadString test_str
        parser.init()
        assert true, parser.parse()
        assert expected, JSON.stringify parser.ast

    describe "4", ->
      test_str = '(ha (42 toto "hey") "blah\\"titi")'
      expected = "{\"type\":\"root\",\"nodes\":[{\"type\":\"list\",\"nodes\":[{\"type\":\"list\",\"nodes\":[{\"type\":\"int\",\"data\":42},{\"type\":\"id\",\"data\":\"toto\"},{\"type\":\"str\",\"data\":\"hey\"}],\"id\":\"\"},{\"type\":\"str\",\"data\":\"blah\\\"titi\"}],\"id\":\"ha\"}]}"

      it "should build an ast tree with nested lists and complex tokens (str) and hooks", ->
        generator = new Generator bnf4
        parser = generator.generate()
        parser.loadString test_str
        parser.init()
        assert true, parser.parse()
        assert expected, JSON.stringify parser.ast

    describe "5", ->
      test_str = '(ha (42 toto "hey") "blah\\"titi" [ 1 2 5 3])'
      expected = "{\"type\":\"root\",\"nodes\":[{\"type\":\"list\",\"nodes\":[{\"type\":\"id\",\"data\":\"ha\"},{\"type\":\"list\",\"nodes\":[{\"type\":\"int\",\"data\":42},{\"type\":\"id\",\"data\":\"toto\"},{\"type\":\"str\",\"data\":\"hey\"}],\"id\":\"42\"},{\"type\":\"str\",\"data\":\"blah\\\"titi\"},{\"type\":\"hash\",\"nodes\":[{\"type\":\"duet\",\"nodes\":[{\"type\":\"int\",\"data\":1},{\"type\":\"int\",\"data\":2}]},{\"type\":\"duet\",\"nodes\":[{\"type\":\"int\",\"data\":5},{\"type\":\"int\",\"data\":3}]}]}],\"id\":\"ha\"}]}"

      it "should build an ast tree, with nested lists/hash", ->
        generator = new Generator bnf5
        parser = generator.generate()
        parser.loadString test_str
        parser.init()
        assert true, parser.parse()
        assert expected, JSON.stringify parser.ast

    describe "6", ->
      test_str = '["ha" 42 "ho" 23] [1 2 5 3]'
      expected = "{\"type\":\"root\",\"nodes\":[{\"type\":\"hash\",\"nodes\":[{\"type\":\"duet\",\"nodes\":[{\"type\":\"str\",\"data\":\"ha\"},{\"type\":\"int\",\"data\":42}],\"key\":\"ha\"},{\"type\":\"duet\",\"nodes\":[{\"type\":\"str\",\"data\":\"ho\"},{\"type\":\"int\",\"data\":23}],\"key\":\"ho\"}]},{\"type\":\"hash\",\"nodes\":[{\"type\":\"duet\",\"nodes\":[{\"type\":\"int\",\"data\":1},{\"type\":\"int\",\"data\":2}],\"key\":1},{\"type\":\"duet\",\"nodes\":[{\"type\":\"int\",\"data\":5},{\"type\":\"int\",\"data\":3}],\"key\":5}]}]}"

      it "should build an ast tree, with nested lists/hash, and peek support", ->
        generator = new Generator bnf6
        parser = generator.generate()
        parser.loadString test_str
        parser.init()
        assert true, parser.parse()
        assert expected, JSON.stringify parser.ast
