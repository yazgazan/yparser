
class Parser
  constructor: ->
    @pos = 0
    @buff = ""
    @caps = new Object
    @line = 1
    @cpos = 1

  loadString: (@buff) ->
    @pos = 0

  remaining: -> @buff[@pos..]

  consume: (n = 1) ->
    for i in [0...n]
      if @buff[@pos + i] is "\n"
        ++@line
        @cpos = 1
      else
        ++@cpos
    @pos += n

  isEnd: -> @pos >= @buff.length

  startCap: (name) -> @caps[name] = @pos

  endCap: (name) -> @buff[@caps[name]...@pos]

  peekChar: (c) ->
    if @isEnd()
      return false
    return c is @buff[@pos]

  peekRange: (a, b) ->
    if @isEnd()
      return false
    if a > b
      return false
    return (@buff[@pos] >= a) and (@buff[@pos] <= b)

  peekText: (s) ->
    if (@pos + s.length) > @buff.length
      return false
    if s is @buff[@pos...(@pos + s.length)]
      return true
    return false

  peekUntil: (c) ->
    if @isEnd()
      return false
    i = @pos
    while i < @buff.length
      if @buff[i] is c
        return i - @pos
      i++
    return false

  peekAny: -> not @isEnd()

  peekAlpha: -> (@peekRange 'a', 'z') or (@peekRange 'A', 'Z')

  peekNum: -> @peekRange '0', '9'

  peekAlphaNum: -> @peekAlpha() or @peekNum()

  peekSpace: -> (@peekChar ' ') or (@peekChar '\t')

  peekAll: -> not @isEnd()

  readChar: (c) ->
    if not @peekChar c
      return false
    @consume()
    return true

  readRange: (a, b) ->
    if not @peekRange a, b
      return false
    @consume()
    return true

  readText: (s) ->
    if not @peekText s
      return false
    @consume s.length
    return true

  readUntil: (c) ->
    n = @peekUntil c
    if n is false
      return false
    @consume n
    return true

  readAny: ->
    if not @peekAny()
      return false
    @consume()
    return true

  readAlpha: ->
    if not @peekAlpha()
      return false
    @consume()
    return true

  readNum: ->
    if not @peekNum()
      return false
    @consume()
    return true

  readAlphaNum: ->
    if not @peekAlphaNum()
      return false
    @consume()
    return true

  readIdentifier: ->
    if not (@readAlpha() or @readChar '_')
      return false
    while @readAlphaNum() or @readChar '_'
      null
    return true

  readSpace: ->
    if not @peekSpace()
      return false
    @consume()
    return true

  readSpaces: ->
    if not @readSpace()
      return false
    while @readSpace()
      null
    return true

  readInt: ->
    if not @readNum()
      return false
    while @readNum()
      null
    return true

  readEOF: -> @isEnd()

  readEOL: -> (@readText "\r\n") or @readChar "\n"

  readAll: ->
    if not @peekAll()
      return false
    n = @buff.length - @pos
    @consume n
    return true

module.exports = Parser

