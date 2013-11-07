
Parser = require "./Parser"

class Token
  constructor: (@data, @type = null) ->
    @line = null
    @pos = null

  setLine: (@line) -> @line
  setPos: (@pos) -> @pos

class Tokenizer extends Parser
  constructor: ->
    @tokRules = new Object
    @tokens = []
    @breakOnUnknownToken = false
    super()

  addTokRule: (type, func) ->
    @tokRules[type] = func

  doToken: (pos, line, backupPos) ->
    data = null
    type = null
    for rule, func of @tokRules
      if func.call this
        data = @endCap 'tok'
        type = rule
        break
      @cpos = pos
      @line = line
      @pos = backupPos
    return [data, type]

  handleUnknownToken: (type, data, line) ->
    if type is null
      @startCap 'tok'
      @readAny()
      data = @endCap 'tok'
      if @breakOnUnknownToken is true
        _line = @reconstructLine line, data
        _cursor = @_generateCursor @cpos
        msg = "unkown token '#{data}':\n#{_line}\n#{_cursor}"
        throw Error msg
    return data

  tokenize: ->
    @tokens = []
    while not @isEnd()
      line = @line
      pos = @cpos
      backupPos = @pos
      @startCap 'tok'
      [data, type] = @doToken pos, line, backupPos
      data = @handleUnknownToken type, data, line
      token = new Token data, type
      token.setLine line
      token.setPos pos
      @tokens.push token
    null

  _generateCursor: (n) ->
    ret = ""
    ret += " " for i in [1...(n - 2)]
    ret += "^"
    return ret

  reconstructLine: (line, data = "") ->
    _line = ""
    backupPos = @pos
    for tok in @tokens
      if tok.line is line
        if tok.data isnt undefined
          _line += (tok.data.split "\n")[0]
    _line += data
    while not (@readEOL() or @isEnd())
      if @buf[@pos] isnt undefined
        _line += @buff[@pos]
      ++@pos
    @pos = backupPos
    return _line

  setBreakOnUnknownToken: (@breakOnUnknownToken = true) -> @breakOnUnknownToken

  lastToken: -> @tokens[-1..][0]

Tokenizer.Token = Token
Tokenizer.Parser = Parser
module.exports = Tokenizer

