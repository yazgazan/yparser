
YParser = require '../lib/YParser'

AstToken = YParser.AstToken
Ast = YParser.Ast

assert = (expected, actual) ->
  if (expected isnt undefined) and (actual isnt undefined)
    if expected is actual
      return
  err = new Error
  err.expected = "" + expected
  err.actual = "" + actual
  throw err

describe "AstToken", ->
  it "should construct a copy of the token. Only type and data should appear in JSON", ->
    baseToken =
      type: 'id'
      data: 'test'
      line: 42
      pos: 23
      garbageData: 'haha'
    token = new AstToken baseToken
    assert 'id', token.type
    assert 'test', token.data
    assert 42, token.line()
    assert 23, token.pos()
    assert "#{undefined}", "#{token.garbageData}"
    assert 'haha', token.token().garbageData

describe "Ast", ->
  describe "#construct", ->
    it "should construct a clean ast node", ->
      node = new Ast
      assert null, node.type
      assert 0, node.nodes.length
      node = new Ast "node_type"
      assert "node_type", node.type
      assert 0, node.nodes.length

  describe "#new", ->
    it "should create a new Ast node, add it to nodes and return it", ->
      node = new Ast
      subnode = node.new "test"
      assert 1, node.nodes.length
      assert "test", subnode.type
      assert 0, subnode.nodes.length

  describe "#addToken", ->
    it "should create a new AstToken from token and push it to nodes. return the AstToken", ->
      baseToken =
        type: 'id'
        data: 'test'
        line: 42
        pos: 23
        garbageData: 'haha'
      node = new Ast
      token = node.addToken baseToken
      assert 1, node.nodes.length
      assert 'id', token.type
      assert 'test', token.data
      assert 42, token.line()
      assert 23, token.pos()
      assert "#{undefined}", "#{token.garbageData}"
      assert 'haha', token.token().garbageData

describe "YParser", ->
  describe "#constructor", ->
    it "should construct a clean YParser", ->
      parser = new YParser
      assert "", parser.buff
      assert 0, parser.pos
      assert 1, parser.line
      assert 1, parser.cpos
      assert false, parser.breakOnUnknownToken
      assert 0, parser.tokens.length

  describe "#init", ->
    it "should load s if any, create  a root node and tokenize the string", ->
      test_str = "toto  ha42 blah"
      parser = new YParser
      parser.addTokRule "id", -> @readIdentifier()
      parser.addTokRule "spaces", -> @readSpaces()
      parser.init test_str
      assert 'id', parser.tokens[0].type
      assert 'toto', parser.tokens[0].data
      assert 1, parser.tokens[0].line
      assert 1, parser.tokens[0].pos

      assert 'spaces', parser.tokens[1].type
      assert 1, parser.tokens[1].line
      assert 5, parser.tokens[1].pos

      assert 'id', parser.tokens[2].type
      assert 'ha42', parser.tokens[2].data
      assert 1, parser.tokens[2].line
      assert 7, parser.tokens[2].pos

      assert 'spaces', parser.tokens[3].type
      assert 1, parser.tokens[3].line
      assert 11, parser.tokens[3].pos

      assert 'id', parser.tokens[4].type
      assert 'blah', parser.tokens[4].data
      assert 1, parser.tokens[4].line
      assert 12, parser.tokens[4].pos

  describe "#peekToken", ->
    it "should return the token if next token is of type `type`, returns null otherwise. returns the next token if no type provided", ->
      test_str = "toto  ha42 blah"
      parser = new YParser
      parser.addTokRule "id", -> @readIdentifier()
      parser.addTokRule "spaces", -> @readSpaces()
      parser.init test_str
      token = parser.peekToken 'id'
      assert true, (token isnt null)
      assert 'id', token.type
      ++parser.curToken
      token = parser.peekToken 'id'
      assert null, token
      token = parser.peekToken 'spaces'
      assert true, (token isnt null)
      assert 'spaces', token.type
      ++parser.curToken
      token = parser.peekToken()
      assert true, (token isnt null)
      assert 'id', token.type

  describe "#getToken", ->
    it "should work like peekToken but move curToken to the next token", ->
      test_str = "toto  ha42 blah"
      parser = new YParser
      parser.addTokRule "id", -> @readIdentifier()
      parser.addTokRule "spaces", -> @readSpaces()
      parser.init test_str
      token = parser.getToken 'id'
      assert true, (token isnt null)
      assert 'id', token.type
      token = parser.getToken 'id'
      assert null, token
      token = parser.getToken 'spaces'
      assert true, (token isnt null)
      assert 'spaces', token.type
      token = parser.getToken()
      assert true, (token isnt null)
      assert 'id', token.type

  describe "#isEndToken", ->
    it "should return true if all token are read, returns false otherwise", ->
      test_str = "toto  ha42 blah"
      parser = new YParser
      parser.addTokRule "id", -> @readIdentifier()
      parser.addTokRule "spaces", -> @readSpaces()
      parser.init test_str
      assert false, parser.isEndToken()
      parser.getToken()
      assert false, parser.isEndToken()
      parser.getToken()
      assert false, parser.isEndToken()
      parser.getToken()
      assert false, parser.isEndToken()
      parser.getToken()
      assert false, parser.isEndToken()
      parser.getToken()
      assert true, parser.isEndToken()

  describe "#addRule", ->
    it "should register the given parsing rule", ->
      parser = new YParser
      assert 42, parser.addRule 'test', 42
      assert 42, parser.rules['test']

  describe "#_readToken", ->
    it "should consume and return true if peekToken isnt null, false otherwise", ->
      test_str = "toto  ha42 blah"
      parser = new YParser
      parser.addTokRule "id", -> @readIdentifier()
      parser.addTokRule "spaces", -> @readSpaces()
      parser.init test_str
      assert true, parser._readToken 'id'
      assert false, parser._readToken 'id'
      assert true, parser._readToken 'spaces'
      assert true, parser._readToken()

  describe "#repeat", ->
    describe "'1'", ->
      it "should return like func, func is called only once", ->
        parser = new YParser
        assert true, parser.repeat "1", -> true
        assert false, parser.repeat "1", -> false

    describe "'?'", ->
      it "should return true on any cases, func is called only once", ->
        parser = new YParser
        assert true, parser.repeat "?", -> true
        assert true, parser.repeat "?", -> false

    describe "'*'", ->
      it "should return true on any cases, func is called as long as it returns true", ->
        parser = new YParser
        i = 0
        assert true, parser.repeat "*", ->
          ++i
          if i >= 10
            return false
          return true
        assert 10, i
        i = 0
        assert true, parser.repeat "*", ->
          ++i
          if i > 0
            return false
          return true
        assert 1, i

    describe "'+'", ->
      it "should return true if func returns true at least on first call, func is called as long as it returns true", ->
        parser = new YParser
        i = 0
        assert true, parser.repeat "+", ->
          ++i
          if i >= 10
            return false
          return true
        assert 10, i
        i = 0
        assert false, parser.repeat "+", ->
          ++i
          if i > 0
            return false
          return true
        assert 1, i

  describe "#readToken", ->
    it "should read the given token, given the repeater, returns like repeat", ->
      test_str = "aaabbbd"
      parser = new YParser
      parser.addTokRule "a", -> @readChar 'a'
      parser.addTokRule "b", -> @readChar 'b'
      parser.addTokRule "c", -> @readChar 'c'
      parser.addTokRule "d", -> @readChar 'd'
      parser.init test_str
      assert true, parser.readToken 'a', '1'
      assert false, parser.readToken 'b', '1'
      assert true, parser.readToken 'a', '*'
      assert false, parser.readToken 'a', '1'
      assert true, parser.readToken 'a', '*'
      assert true, parser.readToken 'b', '+'
      assert false, parser.readToken 'b', '+'
      assert true, parser.readToken 'b', '?'
      assert true, parser.readToken 'd', '?'

  describe "#parse", ->
    describe "no ast", ->
      it "should parse the string using the given the entry rule", ->
        test_str = "(print test toto 42)"
        parser = new YParser
        parser.addTokRule 'PARO', -> @readChar '('
        parser.addTokRule 'PARC', -> @readChar ')'
        parser.addTokRule 'id', -> @readIdentifier()
        parser.addTokRule 'int', -> @readInt()
        parser.addTokRule 'spaces', -> @readSpaces()

        parser.addRule "main", ->
          @getToken 'spaces'
          if not @readToken 'PARO'
            return false
          if not @parse "tokens"
            return false
          @getToken 'spaces'
          if not @readToken 'PARC'
            return false
          @getToken 'spaces'
          return true
        parser.addRule "tokens", -> @repeat "*", -> @parse "token"
        parser.addRule "token", ->
          @getToken 'spaces'
          return (@getToken 'id') or (@getToken 'int')
        parser.init test_str
        assert true, parser.parse "main"
        assert true, parser.isEndToken()

    describe "ast", ->
      it "should parse the string and build the ast given the entry rule", ->
        test_str = "(print test toto (add 42 3) ())"
        parser = new YParser
        parser.addTokRule 'PARO', -> @readChar '('
        parser.addTokRule 'PARC', -> @readChar ')'
        parser.addTokRule 'id', -> @readIdentifier()
        parser.addTokRule 'int', -> @readInt()
        parser.addTokRule 'spaces', -> @readSpaces()

        parser.addRule "main", (ast) ->
          @getToken 'spaces'
          if not @parse "list"
            return false
          @getToken 'spaces'
          return true

        parser.addRule "list", (ast) ->
          curAst = new Ast "list"
          if not @getToken "PARO"
            return false
          if not @parse "tokens", curAst
            return false
          @getToken 'spaces'
          if not @getToken "PARC"
            return false
          ast.nodes.push curAst
          return true

        parser.addRule "tokens", (ast) ->
          @repeat "*", ->
            @getToken 'spaces'
            return @parse "token", ast

        parser.addRule "token", (ast) ->
          return (@parse "id", ast) or (@parse "int", ast) or (@parse "list", ast)

        parser.addRule "id", (ast) ->
          token = @getToken "id"
          if token is null
            return false
          ast.addToken token
          return true

        parser.addRule "int", (ast) ->
          token = @getToken "int"
          if token is null
            return false
          ast.addToken token
          return true

        parser.init test_str
        assert true, parser.parse "main"
        assert true, parser.isEndToken()
        ast = JSON.stringify parser.ast
        expectedAst = "{\"type\":\"root\",\"nodes\":[{\"type\":\"list\",\"nodes\":[{\"type\":\"id\",\"data\":\"print\"},{\"type\":\"id\",\"data\":\"test\"},{\"type\":\"id\",\"data\":\"toto\"},{\"type\":\"list\",\"nodes\":[{\"type\":\"id\",\"data\":\"add\"},{\"type\":\"int\",\"data\":\"42\"},{\"type\":\"int\",\"data\":\"3\"}]},{\"type\":\"list\",\"nodes\":[]}]}]}"
        assert expectedAst, ast

  describe "#recreateLine", ->
    it "should recreate the line where the given token can be found", ->
      test_str = "(print test toto (add 42 3) ())"
      parser = new YParser
      parser.addTokRule 'PARO', -> @readChar '('
      parser.addTokRule 'PARC', -> @readChar ')'
      parser.addTokRule 'id', -> @readIdentifier()
      parser.addTokRule 'int', -> @readInt()
      parser.addTokRule 'spaces', -> @readSpaces()

      parser.addRule "main", (ast) ->
        @getToken 'spaces'
        if not @parse "list"
          return false
        @getToken 'spaces'
        return true

      parser.addRule "list", (ast) ->
        curAst = new Ast "list"
        if not @getToken "PARO"
          return false
        if not @parse "tokens", curAst
          return false
        @getToken 'spaces'
        if not @getToken "PARC"
          return false
        ast.nodes.push curAst
        return true

      parser.addRule "tokens", (ast) ->
        @repeat "*", ->
          @getToken 'spaces'
          return @parse "token", ast

      parser.addRule "token", (ast) ->
        return (@parse "id", ast) or (@parse "int", ast) or (@parse "list", ast)

      parser.addRule "id", (ast) ->
        token = @getToken "id"
        if token is null
          return false
        ast.addToken token
        return true

      parser.addRule "int", (ast) ->
        token = @getToken "int"
        if token is null
          return false
        ast.addToken token
        return true

      parser.init test_str
      assert true, parser.parse "main"
      assert true, parser.isEndToken()
      node = parser.ast.nodes[0].nodes[2]
      assert test_str, parser.recreateLine node

