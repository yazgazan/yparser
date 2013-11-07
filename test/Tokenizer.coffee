
Tokenizer = require '../lib/Tokenizer'

Token = Tokenizer.Token

assert = (expected, actual) ->
  if (expected isnt undefined) and (actual isnt undefined)
    if expected is actual
      return
  err = new Error
  err.expected = "" + expected
  err.actual = "" + actual
  throw err

describe "Tokenizer", ->
  describe "#constructor", ->
    it "should construct a clean Tokenizer", ->
      parser = new Tokenizer
      assert "", parser.buff
      assert 0, parser.pos
      assert 1, parser.line
      assert 1, parser.cpos
      assert false, parser.breakOnUnknownToken
      assert 0, parser.tokens.length

  describe "#addTokRule", ->
    it "should add tu rule to the @tokRules object. dont check the type", ->
      parser = new Tokenizer
      assert 42, parser.addTokRule "test1", 42
      assert 42, parser.tokRules["test1"]

  describe "#tokenize", ->
    it "should tokenize string given the added rules", ->
      test_str = "blah42 23  haha"
      parser = new Tokenizer
      parser.addTokRule "ha", ->
        if not @readText "ha"
          return false
        while @readText "ha"
          null
        return true
      parser.addTokRule "id", -> @readIdentifier()
      parser.addTokRule "int", -> @readInt()
      parser.addTokRule "spaces", -> @readSpaces()
      parser.loadString test_str
      parser.tokenize()
      assert 5, parser.tokens.length
      assert "id", parser.tokens[0].type
      assert "blah42", parser.tokens[0].data
      assert "spaces", parser.tokens[1].type
      assert "int", parser.tokens[2].type
      assert "23", parser.tokens[2].data
      assert "spaces", parser.tokens[3].type
      assert "ha", parser.tokens[4].type
      assert "haha", parser.tokens[4].data

  describe "#reconstructLine", ->
    it "should reconstruct the line given the provided line number", ->
      test_str = "blah42 \n23  haha"
      parser = new Tokenizer
      parser.addTokRule "ha", ->
        if not @readText "ha"
          return false
        while @readText "ha"
          null
        return true
      parser.addTokRule "id", -> @readIdentifier()
      parser.addTokRule "int", -> @readInt()
      parser.addTokRule "spaces", ->
        if not (@readSpaces() or @readEOL())
          return false
        while @readSpaces() or @readEOL()
          null
        return true
      parser.loadString test_str
      parser.tokenize()
      assert (test_str.split "\n")[0], parser.reconstructLine 1

  describe "#lastToken", ->
    it "should should return the last token", ->
      test_str = "blah42 \n23  haha"
      parser = new Tokenizer
      parser.addTokRule "ha", ->
        if not @readText "ha"
          return false
        while @readText "ha"
          null
        return true
      parser.addTokRule "id", -> @readIdentifier()
      parser.addTokRule "int", -> @readInt()
      parser.addTokRule "spaces", ->
        if not (@readSpaces() or @readEOL())
          return false
        while @readSpaces() or @readEOL()
          null
        return true
      parser.loadString test_str
      parser.tokenize()
      token = parser.lastToken()
      assert "ha", token.type
      assert "haha", token.data
      assert 2, token.line
      assert 5, token.pos

