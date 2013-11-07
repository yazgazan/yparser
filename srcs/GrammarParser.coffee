
DefaultHooks = require './DefaultHooks'
YParser = require './YParser'

class GrammarParser extends DefaultHooks
  constructor: (@_tokenRules = {}, @_rules = {}) ->
    super()
    @setupTokens()
    @setupRules()
    @setupBuiltins()
    @tokenStack = []
    @ruleStack = []

  loadJson: (json) ->
    obj = JSON.parse json
    @_tokenRules = obj._tokenRules
    @_rules = obj._rules
    @setupTokens()
    @setupRules()

  setupTokens: ->
    for name, token of @_tokenRules
      ( (name) => @addTokRule name, =>
        @execToken name
      ) name

  setupRules: ->
    for name, rule of @_rules
      ( (name) => @addRule name, (ast) =>
        @execRule name, ast
      ) name

  setupBuiltins: ->
    @builtins =
      space: -> @readSpaces()
      spaces: -> @readSpaces()
      anyspace: -> @readSpace() or @readEOL()
      anyspaces: -> @repeat "+", -> @readSpaces() or @readEOL()
      eol: -> @readEOL()
      eof: -> @readEOF()
      alpha: -> @readAlpha()
      num: -> @readNum()
      alphanum: -> @readAlphaNum()
      int: -> @readInt()
      id: -> @readIdentifier()
      any: -> @readAny()
      all: -> @readAll()

    @builtinsRules =
      eof: -> @isEndToken()
      false: -> false
      true: -> true

  execAnd: (nodes, cb, ast) ->
    for node in nodes
      if not (@handle => cb.call this, node, ast)
        return false
    return true

  execOr: (nodes, cb, ast) ->
    backupPos = @pos
    backupCPos = @cpos
    backupLine = @line
    for node in nodes
      continue if node.type isnt "not"
      if cb.call this, node, ast
        @pos = backupPos
        @cpos = backupCPos
        @line = backupLine
        return false
    @pos = backupPos
    @cpos = backupCPos
    @line = backupLine
    for node in nodes
      continue if node.type is "not"
      if (@handle => cb.call this, node, ast)
        return true
    return false

  execRule: (name, ast) ->
    if @_rules[name]?
      ret = @handleNode @_rules[name], ast
      return ret
    if @_tokenRules[name]?
      return @readToken name
    if @builtinsRules[name]?
      return @builtinsRules[name].call this
    throw Error "unkown rule '#{name}'."

  handleNode: (node, ast) ->
    curAst = ast
    curCap = null
    if node.ast isnt null
      curAst = new YParser.Ast node.ast
    if node.cap isnt null
      curCap = @curToken
    ret = @execRuleNode node, curAst
    if ret is false
      return false
    if node.ast isnt null
      if node.hook isnt null
        func = null
        if this[node.hook]?
          func = this[node.hook]
        else
          func = @findFunc node.hook
        if func is null
          throw Error "couldn't find hook '#{node.hook}'"
        func.call this, curAst
      ast.nodes.push curAst
    if node.cap isnt null
      cap = @capture curCap
      if node.hook isnt null
        if this[node.hook]?
          cap = this[node.hook].call this, cap
        else
          func = @findFunc node.hook
          if func isnt null
            cap = func.call this, cap
          else
            throw Error "couldn't find hook '#{node.hook}'"
      if node.toField is false
        newTok = ast.addToken @tokens[curCap]
        newTok.type = node.data
        newTok.data = cap
      else
        ast[node.cap] = cap
    return true

  findFunc: (name, obj = this.constructor) ->
    if obj[name]?
      return obj[name]
    if obj.__super__
      return @findFunc name, obj.__super__.constructor
    return null

  capture: (startToken) ->
    ret = ""
    for i in [startToken...@curToken]
      ret += @tokens[i].data
    return ret

  execRuleNode: (node, ast) ->
    _backupPos = @curToken
    ret = @repeat node.repeat, =>
      if node.type is "and"
        return @execAnd node.nodes, @handleNode, ast
      if node.type is "or"
        return @execOr node.nodes, @handleNode, ast
      if node.type is "not"
        backupPos = @curToken
        ret = @handleNode node.nodes[0], ast
        @curToken = backupPos
        return ret
      if node.type is "ID"
        return @execRule node.data, ast
      if node.type is "hook"
        return @triggerHook node.data, ast
      if node.type is "debug"
        console.log "DEBUG : #{node.data}"
        return true
      throw Error "unknown type '#{node.type}'"
    if (ret is false) and (node.orError is true)
      @error()
    if (ret is false) or (node.peek is true)
      @curToken = _backupPos
    return ret

  triggerHook: (name, ast) ->
    func = null
    if this[name]?
      func = this[name]
    else
      func = @findFunc name
    if func is null
      throw Error "couldn't find hook '#{name}'"
    return func.call this, ast

  execToken: (name) ->
    ret = null
    if (@tokenStack.indexOf name) != -1
      if @builtins[name]?
        return @builtins[name].call this
      throw Error "unkown rule '#{name}'"
    @tokenStack.push name
    if @_tokenRules[name]?
      ret = @execTokenNode @_tokenRules[name]
    else if @builtins[name]?
      ret = @builtins[name].call this
    @tokenStack.pop()
    return ret

  execTokenNode: (node) ->
    _backupPos = @pos
    _backupCPos = @cpos
    _backupLine = @line
    ret = @repeat node.repeat, =>
      if node.type is "and"
        return @execAnd node.nodes, @execTokenNode
      if node.type is "or"
        return @execOr node.nodes, @execTokenNode
      if node.type is "not"
        backupPos = @pos
        backupCPos = @cpos
        backupLine = @line
        ret = @execTokenNode node.nodes[0]
        @pos = backupPos
        @cpos = backupCPos
        @line = backupLine
        return ret
      if (node.type is "STR") or (node.type is "STR_DBL")
        return @readText node.data
      if node.type is "ID"
        if @_tokenRules[node.data]? or @builtins[node.data]?
          return @execToken node.data
        throw Error "unkown rule '#{node.data}'"
      throw Error "unknown type '#{node.type}'"
    if node.peek is true
      @pos = _backupPos
      @cpos = _backupCPos
      @line = _backupLine
    return ret

  handle: (cb) ->
    backupPos = @pos
    backupCPos = @cpos
    backupLine = @line
    if cb()
      return true
    @pos = backupPos
    @cpos = backupCPos
    @line = backupLine
    return false

module.exports = GrammarParser

