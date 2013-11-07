
Parser = require '../lib/Parser'

assert = (expected, actual) ->
  if (expected isnt undefined) and (actual isnt undefined)
    if expected is actual
      return
  err = new Error
  err.expected = "" + expected
  err.actual = "" + actual
  throw err

describe "Parser", ->
  describe "#constructor", ->
    it "should construct a clean parser", ->
      parser = new Parser
      assert "", parser.buff
      assert 0, parser.pos
      assert 1, parser.line
      assert 1, parser.cpos

  describe "#loadString", ->
    it "should initialize buffer and pos", ->
      test_str = "toto"
      parser = new Parser
      assert() if (parser.loadString test_str) isnt 0
      assert test_str, parser.buff

  describe "#consume", ->
    it "should move pos n (default to 1)", ->
      test_str = "toto"
      parser = new Parser
      parser.loadString test_str
      assert() if parser.consume() isnt 1
      assert 1, parser.pos
      assert() if parser.consume(2) isnt 3
      assert 3, parser.pos

  describe "#remaining", ->
    it "should return the remaining chars in buff", ->
      test_str = "toto"
      parser = new Parser
      parser.loadString test_str
      parser.consume()
      assert "oto", parser.remaining()

  describe "#isEnd", ->
    it "should return true if pos >= buff.length", ->
      test_str = "ab"
      parser = new Parser
      parser.loadString test_str
      assert false, parser.isEnd()
      parser.consume()
      assert false, parser.isEnd()
      parser.consume()
      assert true, parser.isEnd()

  describe "#startCap", ->
    it "should initialize a cap in @caps", ->
      test_str = "toto"
      cap_name = "testcap"
      parser = new Parser
      parser.loadString test_str
      parser.consume()
      assert() if (parser.startCap cap_name) isnt 1
      assert 1, parser.caps[cap_name]

  describe "#endCap", ->
    it "should return captured data", ->
      test_str = "toto"
      cap_name = "testcap"
      parser = new Parser
      parser.loadString test_str
      parser.consume()
      parser.startCap cap_name
      parser.consume()
      parser.consume()
      cap = parser.endCap cap_name
      assert "ot", cap

  describe "#endCap", ->
    it "should return empty cap when no chars consumed", ->
      test_str = "toto"
      cap_name = "testcap"
      parser = new Parser
      parser.loadString test_str
      parser.consume()
      parser.startCap cap_name
      cap = parser.endCap cap_name
      assert "", cap

  describe "#peekChar", ->
    it "should return false if isEnd or if c doesn't match char at @pos", ->
      test_str = "toto"
      parser = new Parser
      parser.loadString test_str
      ret = parser.peekChar 't'
      assert true, ret
      ret = parser.peekChar 'k'
      assert false, ret
      parser.consume()
      parser.consume()
      parser.consume()
      ret = parser.peekChar 'o'
      assert true, ret
      parser.consume()
      ret = parser.peekChar 'd'
      assert false, ret

  describe "#peekRange", ->
    it "should return false if isEnd or if c isnt between start and end", ->
      test_str = "toto"
      parser = new Parser
      parser.loadString test_str
      ret = parser.peekRange 'a', 'z'
      assert true, ret
      ret = parser.peekRange 'a', 'k'
      assert false, ret
      parser.consume()
      parser.consume()
      parser.consume()
      ret = parser.peekRange 'n', 'q'
      assert true, ret
      parser.consume()
      ret = parser.peekRange 'a', 'z'
      assert false, ret

  describe "#peekText", ->
    it "should return true if text match, false if @pos + s.length > @buff.length", ->
      test_str = "toto titi tata"
      parser = new Parser
      parser.loadString test_str
      ret = parser.peekText 'toto'
      assert true, ret
      ret = parser.peekText 'blah'
      assert false, ret
      parser.consume 5
      ret = parser.peekText 'titi'
      assert true, ret
      parser.consume 7
      ret = parser.peekText 'titi'
      assert false, ret

  describe "#peekUntil", ->
    it "should return n if c is found at pos + n, else return false", ->
      test_str = "abcdefgh jkl"
      parser = new Parser
      parser.loadString test_str
      ret = parser.peekUntil 'c'
      assert 2, ret
      ret = parser.peekUntil 'i'
      assert false, ret
      parser.consume 3
      ret = parser.peekUntil 'c'
      assert false, ret

  describe "#peekAny", ->
    it "should return true if not isEnd", ->
      test_str = "abc"
      parser = new Parser
      parser.loadString test_str
      ret = parser.peekAny()
      assert true, ret
      parser.consume 2
      ret = parser.peekAny()
      assert true, ret
      parser.consume 1
      ret = parser.peekAny()
      assert false, ret

  describe "#peekAlpha", ->
    it "should return true if current char is in ranges a..z or A..Z", ->
      test_str = "a2B*"
      parser = new Parser
      parser.loadString test_str
      ret = parser.peekAlpha()
      assert true, ret
      parser.consume()
      ret = parser.peekAlpha()
      assert false, ret
      parser.consume()
      ret = parser.peekAlpha()
      assert true, ret
      parser.consume()
      ret = parser.peekAlpha()
      assert false, ret
      parser.consume()
      ret = parser.peekAlpha()
      assert false, ret

  describe "#peekAlpha", ->
    it "should return true if current char is in ranges 0..9", ->
      test_str = "2a4*"
      parser = new Parser
      parser.loadString test_str
      ret = parser.peekNum()
      assert true, ret
      parser.consume()
      ret = parser.peekNum()
      assert false, ret
      parser.consume()
      ret = parser.peekNum()
      assert true, ret
      parser.consume()
      ret = parser.peekNum()
      assert false, ret
      parser.consume()
      ret = parser.peekNum()
      assert false, ret

  describe "#peekAlphaNum", ->
    it "should return true if current char is in ranges 0..9", ->
      test_str = "2a4*"
      parser = new Parser
      parser.loadString test_str
      ret = parser.peekAlphaNum()
      assert true, ret
      parser.consume()
      ret = parser.peekAlphaNum()
      assert true, ret
      parser.consume()
      ret = parser.peekAlphaNum()
      assert true, ret
      parser.consume()
      ret = parser.peekAlphaNum()
      assert false, ret
      parser.consume()
      ret = parser.peekAlphaNum()
      assert false, ret

  describe "#peekSpace", ->
    it "should return true if current char a space (' ' or '\\t')", ->
      test_str = " a\tb\n"
      parser = new Parser
      parser.loadString test_str
      ret = parser.peekSpace()
      assert true, ret
      parser.consume()
      ret = parser.peekSpace()
      assert false, ret
      parser.consume()
      ret = parser.peekSpace()
      assert true, ret
      parser.consume()
      ret = parser.peekSpace()
      assert false, ret
      parser.consume()
      ret = parser.peekSpace()
      assert false, ret
      parser.consume()
      ret = parser.peekSpace()
      assert false, ret
      parser.consume()

  describe "#peekAll", ->
    it "should return false if isEnd", ->
      test_str = "abc"
      parser = new Parser
      parser.loadString test_str
      ret = parser.peekAll()
      assert true, ret
      parser.consume 3
      ret = parser.peekAll()
      assert false, ret

  describe "#readChar", ->
    it "should consume 1 char if peekChar returns true. Returns like peekChar", ->
      test_str = "abc"
      parser = new Parser
      parser.loadString test_str
      ret = parser.readChar 'a'
      assert true, ret
      ret = parser.readChar 'a'
      assert false, ret
      ret = parser.readChar 'b'
      assert true, ret
      ret = parser.readChar 'c'
      assert true, ret
      ret = parser.readChar 'c'
      assert false, ret

  describe "#readRange", ->
    it "should consume 1 char if peekRange returns true. Returns like peekRange", ->
      test_str = "abc"
      parser = new Parser
      parser.loadString test_str
      ret = parser.readRange "a", "z"
      assert true, ret
      ret = parser.readRange "c", "z"
      assert false, ret
      ret = parser.readRange "a", "d"
      assert true, ret
      ret = parser.readRange "a", "d"
      assert true, ret
      ret = parser.readRange "a", "z"
      assert false, ret

  describe "#readText", ->
    it "should consume s.length chars if peekText returns true. returns like peekText", ->
      test_str = "toto titi tata"
      parser = new Parser
      parser.loadString test_str
      ret = parser.readText "toto"
      assert true, ret
      ret = parser.readText "titi"
      assert false, ret
      parser.consume()
      ret = parser.readText "titi"
      assert true, ret
      parser.consume()
      parser.consume()
      ret = parser.readText "tata"
      assert false, ret
      ret = parser.readText "ata"
      assert true, ret

  describe "#readUntil", ->
    it "should consume n chars if peekUntil returns n as a number. returns true if peekUntil returned a number, false otherwise", ->
      test_str = "abcd fghij lmnopqr"
      parser = new Parser
      parser.loadString test_str
      ret = parser.readUntil 'c'
      assert true, ret
      assert 2, parser.pos
      ret = parser.readUntil 'e'
      assert false, ret
      assert 2, parser.pos
      ret = parser.readUntil 'l'
      assert true, ret
      ret = parser.readUntil 'z'
      assert false, ret

  describe "#readAny", ->
    it "should consume 1 char if peekAny returns true. returns like peekAny", ->
      test_str = "abc"
      parser = new Parser
      parser.loadString test_str
      ret = parser.readAny()
      assert true, ret
      ret = parser.readAny()
      assert true, ret
      ret = parser.readAny()
      assert true, ret
      ret = parser.readAny()
      assert false, ret

  describe "#readAlpha", ->
    it "should consume 1 char if peekAlpha returns true. returns like peekAlpha", ->
      test_str = "a2B*"
      parser = new Parser
      parser.loadString test_str
      ret = parser.readAlpha()
      assert true, ret
      ret = parser.readAlpha()
      assert false, ret
      parser.readChar "2"
      ret = parser.readAlpha()
      assert true, ret
      ret = parser.readAlpha()
      assert false, ret
      parser.readChar "*"
      ret = parser.readAlpha()
      assert false, ret

  describe "#readNum", ->
    it "should consume 1 char if peekNum returns true. returns like peekNum", ->
      test_str = "2a4*"
      parser = new Parser
      parser.loadString test_str
      ret = parser.readNum()
      assert true, ret
      ret = parser.readNum()
      assert false, ret
      parser.readChar "a"
      ret = parser.readNum()
      assert true, ret
      ret = parser.readNum()
      assert false, ret
      parser.readChar "*"
      ret = parser.readNum()
      assert false, ret

  describe "#readAlphaNum", ->
    it "should consume 1 char if peekAlphaNum returns true. returns like peekAlphaNum", ->
      test_str = "2a4*"
      parser = new Parser
      parser.loadString test_str
      ret = parser.readAlphaNum()
      assert true, ret
      ret = parser.readAlphaNum()
      assert true, ret
      ret = parser.readAlphaNum()
      assert true, ret
      ret = parser.readAlphaNum()
      assert false, ret
      parser.readChar "*"
      ret = parser.readAlphaNum()
      assert false, ret

  describe "#readIdentifier", ->
    it "should consume and return true if can read an identifier", ->
      test_str = "toto42 _ha_21 23a"
      parser = new Parser
      parser.loadString test_str
      ret = parser.readIdentifier()
      assert true, ret
      parser.readSpace()
      ret = parser.readIdentifier()
      assert true, ret
      parser.readChar " "
      ret = parser.readIdentifier()
      assert false, ret
      parser.readText "23a"
      ret = parser.readIdentifier()
      assert false, ret

  describe "#readSpace", ->
    it "should consume 1 if peekSpace returns true. returns like peekSpace", ->
      test_str = " a\t\n"
      parser = new Parser
      parser.loadString test_str
      ret = parser.readSpace()
      assert true, ret
      ret = parser.readSpace()
      assert false, ret
      parser.readAlpha()
      ret = parser.readSpace()
      assert true, ret
      ret = parser.readSpace()
      assert false, ret
      parser.readChar "\n"
      ret = parser.readSpace()
      assert false, ret

  describe "#readSpaces", ->
    it "should consume next spaces. returns true if any space consumed", ->
      test_str = "  a \t b\t\t\n"
      parser = new Parser
      parser.loadString test_str
      ret = parser.readSpaces()
      assert true, ret
      ret = parser.readSpaces()
      assert false, ret
      parser.readChar 'a'
      ret = parser.readSpaces()
      assert true, ret
      ret = parser.readSpaces()
      assert false, ret
      parser.readChar 'b'
      ret = parser.readSpaces()
      assert true, ret
      ret = parser.readSpaces()
      assert false, ret
      parser.readChar "\n"
      ret = parser.readSpaces()
      assert false, ret

  describe "#readInt", ->
    it "should return true if it can read and consume an integer, false otherwise", ->
      test_str = "123 456 23a2"
      parser = new Parser
      parser.loadString test_str
      ret = parser.readInt()
      assert true, ret
      ret = parser.readInt()
      assert false, ret
      parser.readSpace()
      ret = parser.readInt()
      assert true, ret
      parser.readSpace()
      # reads 23
      ret = parser.readInt()
      assert true, ret
      ret = parser.readInt()
      assert false, ret
      parser.readChar 'a'
      ret = parser.readInt()
      assert true, ret
      ret = parser.readInt()
      assert false, ret

  describe "#readEOF", ->
    it "should call isEnd and return alike", ->
      test_str = "ab"
      parser = new Parser
      parser.loadString test_str
      assert false, parser.readEOF()
      parser.consume()
      assert false, parser.readEOF()
      parser.consume()
      assert true, parser.readEOF()

  describe "#readEOL", ->
    it "should return true if it can consume an end-of-line char ('\\n' or '\\r\\n')", ->
      test_str = "\na\r\nb"
      parser = new Parser
      parser.loadString test_str
      assert true, parser.readEOL()
      assert false, parser.readEOL()
      parser.readChar "a"
      assert true, parser.readEOL()
      assert false, parser.readEOL()
      parser.readChar "b"
      assert false, parser.readEOL()

  describe "#readAll", ->
    it "should consume all if peekAll return true. returns like peekAll", ->
      test_str = "blah"
      parser = new Parser
      parser.loadString test_str
      assert true, parser.readAll()
      assert false, parser.readAll()

