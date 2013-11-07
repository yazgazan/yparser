
Tokenizer = require './Tokenizer'

class AstToken
  constructor: (token) ->
    @type = token.type
    @data = token.data
    @line = -> token.line
    @pos = -> token.pos
    @token = -> token
    null

class Ast
  constructor: (@type = null) ->
    @nodes = new Array

  new: (type) ->
    sub = new Ast type
    @nodes.push sub
    return sub

  addToken: (token) ->
    ret = new AstToken token
    @nodes.push ret
    return ret

class YParser extends Tokenizer
  constructor: ->
    @rules = new Object
    super()

  init: (s = null) ->
    if s isnt null
      @loadString s
    @ast = new Ast "root"
    @tokenize()
    @curToken = 0

  isEndToken: -> @curToken is @tokens.length

  peekToken: (type = null) ->
    if @isEndToken()
      return null
    if type isnt null
      if @peekToken().type is type
        return @peekToken()
      return null
    return @tokens[@curToken]

  getToken: (type) ->
    tok = @peekToken type
    if tok is null
      return null
    ++@curToken
    return tok

  parse: (rule = "main", ast = @ast) ->
    if not @rules[rule]?
      throw Error "Unknown rule #{rule}."
    backupPos = @curToken
    ret =  @rules[rule].call this, ast
    if ret is false
      @curToken = backupPos
    return ret

  addRule: (name, func) ->
    @rules[name] = func

  _readToken: (tokName) ->
    if (@peekToken tokName) is null
      return false
    @getToken()
    return true

  repeat: (repeater, func) ->
    if repeater is "1"
      return func.call this
    if repeater is "?"
      func.call this
      return true
    if repeater is "*"
      while func.call this
        null
      return true
    if repeater is "+"
      if not func.call this
        return false
      while func.call this
        null
      return true

  readToken: (tokName, repeater = "1") -> @repeat repeater, -> @_readToken tokName

  recreateLine: (token) ->
    ret = ""
    line = token.line
    if (typeof line) is "function"
      line = token.line()
    for tok in @tokens
      if (tok.line is (line - 1)) and (tok.data.indexOf "\n") isnt -1
        ret += (tok.data.split "\n")[-1..][0]
      if tok.line is line
        ret += (tok.data.split "\n")[0]
    return ret

  generateCursor: (token) ->
    ret = ""
    if token.pos > 1
      for i in [1..(token.pos - 1)]
        console.log i
        ret += " "
    ret += "^"
    return ret

  error: (token = null) ->
    if (token isnt null) and not (token instanceof AstToken)
      token = null
    if token is null
      token = @peekToken()
    if token is null
      token = @tokens[-1..][0]
    console.log token
    line = @recreateLine token
    cursor = @generateCursor token
    msg  = "Error parsing file, unexpected token #{JSON.stringify token.data}"
    msg += " at #{token.line}:#{token.pos}:\n#{line}\n#{cursor}"
    throw Error msg

YParser.Tokenizer = Tokenizer
YParser.AstToken = AstToken
YParser.Ast = Ast
module.exports = YParser

