
YParser = require './YParser'

class BnfParser extends YParser
  constructor: (@bnf) ->
    super()
    @hookName = null
    @capToField = false
    @capName = null
    @astName = null
    @repeater = "1"
    @peek = false
    @orError = false
    @loadString @bnf
    @initTokens()
    @initRules()
    @setBreakOnUnknownToken()
    @init()
    @parseBnf()

  initTokens: ->
    @addTokRule 'SPACE', -> @repeat "+", -> @readSpaces() or @readEOL()
    @addTokRule 'CAP_TO_FIELD', -> @readChar '.'
    @addTokRule 'CAP', -> (not @readText '::') and @readChar ':'
    @addTokRule 'AST', -> @readChar '#'
    @addTokRule 'RULE_ENTRY', -> @readText '::'
    @addTokRule 'TOKEN_ENTRY', -> @readText '='
    @addTokRule 'PEEK', -> @readChar '@'
    @addTokRule 'ID', -> @readIdentifier()
    @addTokRule 'REPEATER', -> (@readChar '+') or (@readChar '*') or (@readChar '?')
    @addTokRule 'RULE_END', -> @readChar ';'
    @addTokRule 'GROUP_START', -> @readChar '['
    @addTokRule 'GROUP_END', -> @readChar ']'
    @addTokRule 'NOT', -> @readChar '^'
    @addTokRule 'OR', -> @readChar '|'
    @addTokRule 'HOOK_START', -> @readChar '('
    @addTokRule 'HOOK_END', -> @readChar ')'
    @addTokRule 'OR_ERROR', -> @readChar '!'

    @addTokRule 'STR', ->
      if not @readChar "'"
        return false
      @repeat "*", ->
        if @readText "\\'"
          return true
        return (not @readChar "'") and @readAny()

    @addTokRule 'STR_DBL', ->
      if not @readChar '"'
        return false
      @repeat "*", ->
        if @readText '\\"'
          return true
        return (not @readChar '"') and @readAny()

  initRules: ->
    @addRule "main", @ruleMain
    @addRule "rule", @ruleRule
    @addRule "tokenRule", @ruleTokenRule
    @addRule "group_body", @ruleGroupBody
    @addRule "or", @ruleOr
    @addRule "and", @ruleAnd
    @addRule "token", @ruleToken
    @addRule "id", @ruleId
    @addRule "not", @ruleNot
    @addRule "cap", @ruleCap
    @addRule "ast", @ruleAst
    @addRule "repeater", @ruleRepeater
    @addRule "group", @ruleGroup
    @addRule "peek", @rulePeek
    @addRule "orError", @ruleOrError
    @addRule "hook", @ruleHook
    @addRule "debug", @ruleDebug

  ruleMain: (ast) ->
    while (@parse "rule", ast) or (@parse "tokenRule", ast)
      @readToken "SPACE"
      if @isEndToken()
        return true
    @error()
    return false

  ruleTokenRule: (ast) ->
    node = new YParser.Ast "tokenRule"
    @readToken "SPACE"
    nameTok = @getToken "ID"
    if nameTok is null
      return false
    node.name = nameTok.data
    @readToken "SPACE"
    if not @readToken "TOKEN_ENTRY"
      return false
    @readToken "SPACE"
    if not @parse "group_body", node
      @error()
    if not @readToken "RULE_END"
      @error()
    ast.nodes.push node
    return true

  ruleRule: (ast) ->
    node = new YParser.Ast "rule"
    @readToken "SPACE"
    nameTok = @getToken "ID"
    if nameTok is null
      return false
    node.name = nameTok.data
    @readToken "SPACE"
    if not @readToken "RULE_ENTRY"
      return false
    @readToken "SPACE"
    if not @parse "group_body", node
      @error()
    if not @readToken "RULE_END"
      @error()
    ast.nodes.push node
    return true

  ruleGroupBody: (ast) ->
    (@parse "or", ast) or (@parse "and", ast)

  ruleOr: (ast) ->
    node = new YParser.Ast "or"
    @handleToken node
    ret = (=> @repeat "+", ->
      if not @parse "token", node
        return false
      @readToken "SPACE"
      if (@peekToken "RULE_END") or (@peekToken "GROUP_END") or (@peekToken "NOT")
        return true
      @readToken "SPACE"
      if not @readToken "OR"
        return false
      @readToken "SPACE"
      return true
    )()
    if ret is false
      @capToField = node.toField
      @capName = node.cap
      @hookName = node.hook
      @astName = node.ast
      @repeater = node.repeat
      @peek = node.peek
      @orError = node.orError
      return false
    @repeat "*", => @parse "not", node
    @readToken "SPACE"
    ast.nodes.push node
    return ret

  ruleAnd: (ast) ->
    node = new YParser.Ast "and"
    @handleToken node
    ret = (=> @repeat "+", ->
      if not @parse "token", node
        return false
      if (@peekToken "RULE_END" or @peekToken "GROUP_END" or @peekToken "NOT")
        return true
      if not @readToken "SPACE"
        return false
      return true
    )()
    if ret is true
      ast.nodes.push node
    else
      @capToField = node.toField
      @capName = node.cap
      @hookName = node.hook
      @astName = node.ast
      @repeater = node.repeat
    return ret

  ruleNot: (ast) ->
    node = new YParser.Ast "not"
    if not @readToken "NOT"
      return false
    @readToken "SPACE"
    @parse "token", node
    @handleToken node
    ast.nodes.push node
    return true

  ruleToken: (ast) ->
    @parse "orError"
    @parse "peek"
    (@parse "cap", ast) or (@parse "ast", ast)
    if @parse "id", ast
      return true
    if @parse "group", ast
      return true
    if @parse "hook", ast
      return true
    if @parse "debug", ast
      return true

    legitTypes = ["STR", "STR_DBL"]
    token = @peekToken()
    return false if token is null
    if (legitTypes.indexOf token.type) is -1
      return false
    token = @getToken()
    @parse "repeater", ast
    token = ast.addToken token
    token.data = @cleanStr token.data
    @handleToken token
    return true

  cleanStr: (s) ->
    ret = ""
    tmp = s[1...-1]
    i = 0
    while i < tmp.length
      if tmp[i] is '\\'
        ret += tmp[i + 1]
        i += 2
        continue
      ret += tmp[i]
      ++i
    return ret

  ruleId: (ast) ->
    if @peekToken "ID"
      tok = @getToken "ID"
      @parse "repeater", ast
      @handleToken ast.addToken tok
      return true
    return false

  ruleGroup: (ast) ->
    if not @readToken "GROUP_START"
      return false
    @readToken "SPACE"
    if not @parse "group_body", ast
      return false
    @readToken "SPACE"
    if not @readToken "GROUP_END"
      return false
    @parse "repeater", ast
    ast.nodes[-1..][0].repeat = @repeater
    @repeater = "1"
    return true

  ruleHook: (ast) ->
    if not @readToken "HOOK_START"
      return false
    hook = @getToken "ID"
    if hook is null
      return false
    if not @readToken "HOOK_END"
      return false
    hook = @handleToken ast.addToken hook
    hook.type = "hook"
    return true

  ruleDebug: (ast) ->
    if not @readToken "HOOK_START"
      return false
    debug = @getToken "STR"
    if debug is null
      debug = @getToken "STR_DBL"
    if debug is null
      return false
    if not @readToken "HOOK_END"
      return false
    debug = @handleToken ast.addToken debug
    debug.type = "debug"
    debug.data = @cleanStr debug.data
    return true

  rulePeek: (ast) ->
    @peek = false
    if @readToken "PEEK"
      @peek = true
      return true
    return false

  ruleOrError: (ast) ->
    @orError = false
    if @readToken "OR_ERROR"
      @orError = true
      return true
    return false

  ruleCap: (ast) ->
    capToField = false
    if @readToken "CAP_TO_FIELD"
      capToField = true
    capName = @getToken "ID"
    if capName is null
      return false
    capName = capName.data
    if @readToken "HOOK_START"
      hookName = @getToken "ID"
      if hookName is null
        @error()
        return false
      @hookName = hookName.data
      if not @readToken "HOOK_END"
        @error()
        return false
    if not @readToken "CAP"
      return false
    @capToField = capToField
    @capName = capName
    return true

  ruleAst: (ast) ->
    astName = @getToken "ID"
    if astName is null
      return false
    astName = astName.data
    if @readToken "HOOK_START"
      hookName = @getToken "ID"
      if hookName is null
        @error()
        return false
      @hookName = hookName.data
      if not @readToken "HOOK_END"
        @error()
        return false
    if not @readToken "AST"
      return false
    @astName = astName
    return true

  ruleRepeater: (ast) ->
    token = @getToken "REPEATER"
    if token is null
      return false
    @repeater = token.data
    return true

  handleToken: (token) ->
    token.toField = @capToField
    token.cap = @capName
    token.hook = @hookName
    token.ast = @astName
    token.repeat = @repeater
    token.peek = @peek
    token.orError = @orError
    @capToField = false
    @capName = null
    @hookName = null
    @astName = null
    @repeater = "1"
    @peek = false
    @orError = false
    return token

  parseBnf: ->
    @parse()
    null

module.exports = BnfParser

