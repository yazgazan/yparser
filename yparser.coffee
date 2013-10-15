
if require?
  fs = require 'fs'

class SimpleParser
  constructor: ->
    @buffer = ''
    @pos = 0
    @captures = new Object
    return

  loadString: (str) ->
    @buffer = str
    @pos = 0
    return true

  peekChar: (c) ->
    if @isEnd()
      false
    @buffer[@pos] is c

  peekRange: (a, b) ->
    if @isEnd()
      false
    if a > b
      throw "peekRange, invalid range"
    (@buffer[@pos] >= a) and (@buffer[@pos] <= b)

  peekText: (str) ->
    if not (@inRange @pos + str.length - 1)
      return false
    start = @pos
    end = @pos + str.length
    if str is @buffer[start...end]
      return true
    return false

  peekUntil: (c) ->
    i = @pos
    while @inRange i
      if @buffer[i] is c
        return i - @pos
      i++
    return false

  peekAlpha: -> (@peekRange 'a', 'z') or (@peekRange 'A', 'Z')

  peekNum: -> @peekRange '0', '9'

  peekAlphaNum: -> @peekAlpha() or @peekNum()

  peekSpace: -> (@peekChar ' ') or (@peekChar '\t')

  peekAnySpace: -> (@peekSpace()) or (@peekText "\r\n") or (@peekChar '\n')

  peekAny: -> not @isEnd()

  consume: (n) ->
    if not @inRange (@pos + n - 1)
      throw "Can't consume '#{n}' chars"
    @pos += n

  inRange: (offset) -> offset < @buffer.length

  isEnd: -> @pos is @buffer.length

  remaining: -> @buffer[@pos..]

  readChar: (c) ->
    if not @peekChar c
      return false
    @consume 1
    return true

  readEOF: -> @isEnd()

  readEOL: -> (@readText "\r\n") or (@readChar '\n')

  readRange: (a, b) ->
    if not @peekRange a, b
      return false
    @consume 1
    return true

  readText: (str) ->
    if not @peekText str
      return false
    @consume str.length
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
    @consume 1
    return true

  readAlpha: ->
    if not @peekAlpha()
      return false
    @consume 1
    return true

  readNum: ->
    if not @peekNum()
      return false
    @consume 1
    return true

  readAlphaNum: ->
    if not @peekAlphaNum()
      return false
    @consume 1
    return true

  readSpace: ->
    if not @peekSpace()
      return false
    @consume 1
    return true

  readAnySpace: ->
    if @peekSpace() or @peekChar '\n'
      @consume 1
      return true
    if @peekText "\r\n"
      @consume 2
      return true
    return false

  readAll: (c) ->
    i = 0
    while @readChar c
      i++
    if i is 0
      return false
    return true

  readIdentifier: ->
    if not (@readAlpha() or @readChar '_')
      return false
    while @readAlphaNum() or @readChar '_'
      null
    return true

  readInteger: ->
    if not @readNum()
      return false
    while @readNum()
      null
    return true

  readStr: ->
    backupPos = @pos
    if not @readChar '"'
      return false
    while true
      if @readText "\\\\"
        continue
      if @readText "\\\""
        continue
      if @readChar '"'
        return true
      if @readEOF()
        break
      @readAny()
    @pos = backupPos
    return false

  beginCapture: (tag) ->
    if @readEOF()
      return false
    @captures[tag] = @pos
    return true

  endCapture: (tag) ->
    if not @captures[tag]?
      return null
    if @pos is @captures[tag]
      return ''
    start = @captures[tag]
    end = @pos
    return @buffer[start...end]

class ExtendedParser extends SimpleParser
  constructor: ->
    @grammars = new Object
    @repeats =
      '1': @execOnce
      '+': @execOnceOrMore
      '*': @execZeroOrMore
      '?': @execOnceOrNot
    @types =
      'or': @execOr
      'and': @execAnd
      'not': @execNot
      'sub': @execSub
      'any': @applyAny
      'all': @applyAll
      'char': @applyChar
      'text': @applyText
      'str': @applyStr
      'range': @applyRange
      'until': @applyUntil
      'alpha': @applyAlpha
      'num': @applyNum
      'alphanum': @applyAlphaNum
      'space': @applySpace
      'anyspace': @applyAnySpace
      'eof': @applyEOF
      'eol': @applyEOL
      'id': @applyId
      'int': @applyInt
      'false' : @applyFalse
      'true' : @applyTrue
    super()

  setGrammar: (name, tree) -> @grammars[name] = tree

  execGrammar: (name) ->
    backupPos = @pos
    if (typeof name) is 'string'
      if not @grammars[name]?
        throw "Can't find grammar for '#{name}'"
      tree = @grammars[name]
    else
      tree = name
    if not @repeats[tree.repeat]?
      throw "unknown repeater '#{tree.repeat}' #{JSON.stringify tree}"
    ret = @repeats[tree.repeat].call this, tree, (tree) =>
      backupPos2 = @pos
      if not @types[tree.type]?
        throw "unknown type '#{tree.type}'"
      ret2 = @types[tree.type].call this, tree
      if ret is false
        @pos = backupPos2
      return ret2
    if ret is false
      @pos = backupPos
    if tree.peek? and tree.peek is true
      @pos = backupPos
    return ret

  execOnce: (tree, cb) -> cb tree

  execOnceOrMore: (tree, cb) ->
    backupPos = @pos
    i = 0
    while cb tree
      i++
    if i is 0
      @pos = backupPos
      return false
    return true

  execZeroOrMore: (tree, cb) ->
    while cb tree
      null
    return true

  execOnceOrNot: (tree, cb) ->
    cb tree
    return true

  execOr: (tree) ->
    origPos = @pos
    ret = false
    for node in tree.nodes
      if node.type is 'not'
        newPos = @pos
        @pos = origPos
        if @execGrammar node
          @pos = origPos
          return false
        @pos = newPos
      if (ret is false) and @execGrammar node
        ret = true
    return ret

  execAnd: (tree) ->
    backupPos = @pos
    for node in tree.nodes
      if node.type is 'not' and @execGrammar node
        @pos = backupPos
        return false
      if not @execGrammar node
        @pos = backupPos
        return false
    return true

  execNot: (tree) ->
    backupPos = @pos
    ret = @execOr tree
    @pos = backupPos
    return ret

  execSub: (tree) ->
    ret = @execGrammar tree.nodes[0]
    return ret

  applyAny: (tree) -> @readAny()

  applyAll: (tree) -> @readAll tree.nodes[0]

  applyChar: (tree) -> @readChar tree.nodes[0]

  applyText: (tree) -> @readText tree.nodes[0]

  applyStr: (tree) -> @readStr()

  applyRange: (tree) -> @readRange tree.nodes[0], tree.nodes[1]

  applyUntil: (tree) -> @readUntil tree.nodes[0]

  applyAlpha: (tree) -> @readAlpha()

  applyNum: (tree) -> @readNum()

  applyAlphaNum: (tree) -> @readAlphaNum()

  applySpace: (tree) -> @readSpace()

  applyAnySpace: (tree) -> @readAnySpace()

  applyEOF: (tree) -> @readEOF()

  applyEOL: (tree) -> @readEOL()

  applyId: (tree) -> @readIdentifier()

  applyInt: (tree) -> @readInteger()

  applyFalse: (tree) -> false
  applyTrue: (tree) -> true


class AstParser extends ExtendedParser
  constructor: ->
    @initAst()
    @triggers = new Object
    @curCap = 0
    @lastRemaining = null
    @nocapmode = false
    super()

  initAst: (ast = null) ->
    if ast is null
      @ast = new Object
      @ast.nodes = new Array
    else
      @ast = ast
    @astStack = new Array
    @astStack.push @ast
    return @ast

  loadString: (str) ->
    super str

  loadFile: (filename, cb) ->
    fileContent = fs.readFile filename, {encoding: 'ascii'}, (err, data) =>
      if err
        throw err
      @loadString data
      cb.call this

  register: (name, fn) ->
    @triggers[name] = fn

  topAst: -> @astStack[-1..][0]

  execGrammar: (name) ->
    newAst = null
    cbAst = null
    popWhenDone = false
    capToRead = null
    if (typeof name) is 'string'
      if not @grammars[name]?
        throw "Can't find grammar for '#{name}'"
      tree = @grammars[name]
    else
      tree = name
    if @nocapmode is true
      return super tree
    if tree.ast?
      if not @triggers[tree.ast]?
        newAst = new Object
        newAst.type = tree.ast
        newAst.nodes = new Array
        # throw "Can't find trigger '#{tree.ast}'"
      else
        newAst = @triggers[tree.ast].call this, @topAst()
      if (typeof newAst) is 'function'
        cbAst = newAst
      else if newAst isnt null
        popWhenDone = true
        @astStack.push newAst
    if tree.cap?
      @beginCapture "cap_#{@curCap}"
      capToRead = @curCap
      @curCap++

    res = super tree

    if (res is true) and tree.cap?
      cap = @endCapture "cap_#{capToRead}"
      if cap is null
        cap = ''
      if @lastRemaining isnt @remaining()
        if tree.cap[-1..] is '!'
          capname = tree.cap[..-2]
          cap = @removeEscape cap
        else
          capname = tree.cap
        if not @triggers[capname]?
          if tree.capField is true
            @topAst()[capname] = cap
          else
            newNode = new Object
            newNode.type = capname
            # newNode.value = cap
            newNode.nodes = new Array
            newNode.nodes.push cap
        else
          newNode = @triggers[capname].call this, @topAst(), cap
        @lastRemaining = @remaining()
        if (tree.capField isnt true) and newNode isnt null
          @topAst().nodes.push newNode
    if cbAst isnt null
      if res is true
        cbAst.call this, @topAst()
    else if popWhenDone is true
      @astStack.pop()
      if res is true
        @topAst().nodes.push newAst
    return res

  removeEscape: (str) ->
    str = str[1..-2]
    ret = ""
    i = 0
    while i < str.length
      if str[i] is '\\'
        i++
        ret += str[i]
      else
        ret += str[i]
      ++i
    return ret

  execOnce: (tree, cb) ->
    if @nocapmode is true
      return super tree, cb
    @nocapmode = true
    backupPos = @pos
    if (super tree, cb) is false
      @pos = backupPos
      @nocapmode = false
      return false
    @pos = backupPos
    @nocapmode = false
    return super tree, cb

  execOnceOrMore: (tree, cb) ->
    if @nocapmode is true
      return super tree, cb
    @nocapmode = true
    backupPos = @pos
    if (super tree, cb) is false
      @pos = backupPos
      @nocapmode = false
      return false
    @pos = backupPos
    @nocapmode = false
    return super tree, cb

  execZeroOrMore: (tree, cb) ->
    if @nocapmode is true
      return super tree, cb
    @nocapmode = true
    backupPos = @pos
    if (super tree, cb) is false
      @pos = backupPos
      @nocapmode = false
      return false
    @pos = backupPos
    @nocapmode = false
    return super tree, cb

  execOnceOrNot: (tree, cb) ->
    if @nocapmode is true
      return super tree, cb
    @nocapmode = true
    backupPos = @pos
    if (super tree, cb) is false
      @pos = backupPos
      @nocapmode = false
      return false
    @pos = backupPos
    @nocapmode = false
    return super tree, cb

  execOr: (tree) ->
    if @nocapmode is true
      return super tree
    @nocapmode = true
    backupPos = @pos
    if (super tree) is false
      @pos = backupPos
      @nocapmode = false
      return false
    @pos = backupPos
    @nocapmode = false
    return super tree

  execAnd: (tree) ->
    if @nocapmode is true
      return super tree
    @nocapmode = true
    backupPos = @pos
    if (super tree) is false
      @pos = backupPos
      @nocapmode = false
      return false
    @pos = backupPos
    @nocapmode = false
    return super tree

  execNot: (tree) ->
    if @nocapmode is true
      return super tree
    @nocapmode = true
    backupPos = @pos
    if (super tree) is false
      @pos = backupPos
      @nocapmode = false
      return false
    @pos = backupPos
    @nocapmode = false
    return super tree

  execSub: (tree) ->
    if @nocapmode is true
      return super tree
    @nocapmode = true
    backupPos = @pos
    if (super tree) is false
      @pos = backupPos
      @nocapmode = false
      return false
    @pos = backupPos
    @nocapmode = false
    return super tree

class GrammarParser extends AstParser
  constructor: ->
    super()
    @initGrammar()

  initAst: ->
    ast =
      type: 'undefined'
      repeat: '1'
      nodes: new Array
    return super ast

  loadString: (str) ->
    @lastAst = null
    @lastCap = null
    @capToField = false
    @goingForNot = false
    @goingForPeek = false
    super str

  loadGrammar: ->
    grammarParser = new AstParser
    if not @execGrammar 'main'
      return false
    for rule in @ast.nodes
      grammarParser.setGrammar rule.name, rule.nodes[0]
    return grammarParser

  createNotNode: ->
    node = new Object
    node.type = 'not'
    node.repeat = '1'
    node.cap = null
    node.ast = null
    node.nodes = new Array
    return node

  initGrammar: ->
    @setGrammar '_str',
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

    @setGrammar '_id',
      type: 'and'
      repeat: '1'
      nodes: [
        {
          type: 'or'
          repeat: '1'
          nodes: [
            {
              type: 'alpha'
              repeat: '1'
              nodes: []
            },{
              type: 'char'
              repeat: '1'
              nodes: ['_']
            }
          ]
        },{
          type: 'or'
          repeat: '*'
          nodes: [
            {
              type: 'alphanum'
              repeat: '1'
              nodes: []
            },{
              type: 'char'
              repeat: '1'
              nodes: ['_']
            }
          ]
        }
      ]

    @setGrammar 'cap',
      type: 'and'
      repeat: '1'
      cap: 'cap'
      nodes: [
        {
          type: 'sub'
          repeat: '1'
          nodes: ['_id']
        },{
          type: 'char'
          repeat: '1'
          nodes: [':']
        }
      ]

    @setGrammar 'capstr',
      type: 'and'
      repeat: '1'
      cap: 'capstr'
      nodes: [
        {
          type: 'sub'
          repeat: '1'
          nodes: ['_id']
        },{
          type: 'char'
          repeat: '1'
          nodes: ['!']
        }
      ]

    @setGrammar 'ast',
      type: 'and'
      repeat: '1'
      cap: 'ast'
      nodes: [
        {
          type: 'sub'
          repeat: '1'
          nodes: ['_id']
        },{
          type: 'char'
          repeat: '1'
          nodes: ['#']
        }
      ]

    @setGrammar 'keywords',
      type: 'or'
      repeat: '1'
      nodes: [
        {
          type: 'text'
          repeat: '1'
          nodes: ['anyspace']
        },{
          type: 'text'
          repeat: '1'
          nodes: ['any']
        },{
          type: 'text'
          repeat: '1'
          nodes: ['all']
        },{
          type: 'text'
          repeat: '1'
          nodes: ['alphanum']
        },{
          type: 'text'
          repeat: '1'
          nodes: ['str']
        },{
          type: 'text'
          repeat: '1'
          nodes: ['alpha']
        },{
          type: 'text'
          repeat: '1'
          nodes: ['num']
        },{
          type: 'text'
          repeat: '1'
          nodes: ['space']
        },{
          type: 'text'
          repeat: '1'
          nodes: ['eof']
        },{
          type: 'text'
          repeat: '1'
          nodes: ['eol']
        },{
          type: 'text'
          repeat: '1'
          nodes: ['id']
        },{
          type: 'text'
          repeat: '1'
          nodes: ['int']
        },{
          type: 'text'
          repeat: '1'
          nodes: ['false']
        },{
          type: 'text'
          repeat: '1'
          nodes: ['true']
        }
      ]

    @setGrammar 'native_token',
      type: 'or'
      repeat: '1'
      nodes: [
        {
          type: 'sub'
          repeat: '1'
          cap: 'keyword'
          nodes: ['keywords']
        },{
          type: 'sub'
          repeat: '1'
          cap: 'id'
          nodes: ['_id']
        },{
          type: 'sub'
          repeat: '1'
          cap: 'str'
          nodes: ['_str']
        }
      ]

    @setGrammar 'token_separator',
      type: 'or'
      repeat: '1'
      nodes: [
        {
          type: 'and'
          repeat: '1'
          ast: 'or'
          nodes: [
            {
              type: 'anyspace'
              repeat: '*'
              nodes: []
            },{
              type: 'char'
              repeat: '1'
              nodes: ['|']
            },{
              type: 'anyspace'
              repeat: '*'
              nodes: []
            }
          ]
        },{
          type: 'and'
          repeat: '1'
          ast: 'not'
          nodes: [
            {
              type: 'anyspace'
              repeat: '*'
              nodes: []
            },{
              type: 'char'
              repeat: '1'
              nodes: ['^']
            },{
              type: 'anyspace'
              repeat: '*'
              nodes: []
            }
          ]
        },{
          type: 'anyspace'
          repeat: '+'
          ast: 'and'
          nodes: []
        }
      ]

    @setGrammar 'repeater',
      type: 'or'
      repeat: '1'
      cap: 'repeater'
      nodes: [
        {
          type: 'char'
          repeat: '1'
          nodes: ['?']
        },{
          type: 'char'
          repeat: '1'
          nodes: ['+']
        },{
          type: 'char'
          repeat: '1'
          nodes: ['*']
        }
      ]

    @setGrammar 'token_group',
      type: 'and'
      repeat: '1'
      nodes: [
        {
          type: 'char'
          repeat: '1'
          nodes: ['[']
        },{
          type: 'anyspace'
          repeat: '*'
          nodes: []
        },{
          type: 'sub'
          repeat: '1'
          nodes: ['token']
        },{
          type: 'and'
          repeat: '*'
          nodes: [
            {
              type: 'sub'
              repeat: '1'
              nodes: ['token_separator']
            },{
              type: 'sub'
              repeat: '1'
              nodes: ['token']
            }
          ]
        },{
          type: 'anyspace'
          repeat: '*'
          nodes: []
        },{
          type: 'char'
          repeat: '1'
          ast: 'closing_group'
          nodes: [']']
        }
      ]

    @setGrammar 'token_content',
      type: 'or'
      repeat: '1'
      nodes: [
        {
          type: 'sub'
          repeat: '1'
          nodes: ['native_token']
        },{
          type: 'sub'
          repeat: '1'
          ast: 'group'
          nodes: ['token_group']
        }
      ]

    @setGrammar 'capsub',
      type: 'and'
      repeat: '1'
      nodes: [
        {
          type: 'char'
          repeat: '?'
          cap: 'capfield'
          nodes: ['.']
        },{
          type: 'or'
          repeat: '1'
          nodes: [
            {
              type: 'sub'
              repeat: '1'
              nodes: ['capstr']
            },{
              type: 'sub'
              repeat: '1'
              nodes: ['cap']
            }
          ]
        }
      ]

    @setGrammar 'token',
      type: 'and'
      repeat: '1'
      nodes: [
        {
          type: 'sub'
          repeat: '?'
          nodes: ["capsub"]
        },{
          type: 'sub'
          repeat: '?'
          nodes: ['ast']
        },{
          type: 'sub'
          repeat: '?'
          nodes: ['peek']
        },{
          type: 'sub'
          repeat: '1'
          nodes: ['token_content']
        },{
          type: 'sub'
          repeat: '?'
          nodes: ['repeater']
        }
      ]

    @setGrammar 'peek',
      type: 'text'
      repeat: '1'
      ast: 'peek'
      nodes: ['%']

    @setGrammar 'rule',
      type: 'and'
      repeat: '1'
      ast: 'rule'
      nodes: [
        {
          type: 'anyspace'
          repeat: '*'
          nodes: []
        },{
          type: 'sub'
          repeat: '1'
          nodes: ['token']
        },{
          type: 'and'
          repeat: '*'
          nodes: [
            {
              type: 'sub'
              repeat: '1'
              nodes: ['token_separator']
            },{
              type: 'sub'
              repeat: '1'
              nodes: ['token']
            }
          ]
        },{
          type: 'anyspace'
          repeat: '*'
          nodes: []
        }
      ]

    @setGrammar 'main',
      type: 'and'
      repeat: '*'
      nodes: [
        {
          type: 'and'
          repeat: '1'
          ast: 'newrule'
          nodes: [
            {
              type: 'anyspace'
              repeat: '*'
              nodes: []
            },{
              type: 'sub'
              repeat: '1'
              cap: 'rulename'
              nodes: ['_id']
            },{
              type: 'space'
              repeat: '*'
              nodes: []
            },{
              type: 'text'
              repeat: '1'
              nodes: ["::"]
            },{
              type: 'anyspace'
              repeat: '*'
              nodes: []
            },{
              type: 'sub'
              repeat: '1'
              ast: 'rulecore'
              nodes: ['rule']
            },{
              type: 'anyspace'
              repeat: '*'
              nodes: []
            },{
              type: 'char'
              repeat: '1'
              nodes: [';']
            }
          ]
        }
      ]

    @register 'or', (ast) ->
      return (ast) ->
        if ast.type is 'undefined'
          ast.type = 'or'
          return null
        if ast.type is 'or'
          return null
        return null

    @register 'not', (ast) ->
      return ->
        if ast.type is 'undefined'
          ast.type = 'or'
        @goingForNot = true

    @register 'and', (ast) ->
      return (ast) ->
        if ast.type is 'undefined'
          ast.type = 'and'
          return null
        if ast.type is 'and'
          return null
        return null

    @register 'id', (ast, cap) ->
      node = new Object
      node.type = 'sub'
      node.repeat = '1'
      node.ast = null
      node.cap = null
      node.nodes = new Array
      node.nodes.push cap
      if @lastAst isnt null
        node.ast = @lastAst
        @lastAst = null
      if @lastCap isnt null
        if @capToField is true
          node.capField = true
          @capToField = false
        node.cap = @lastCap
        @lastCap = null
      if @goingForPeek is true
        @goingForPeek = false
        node.peek = true
      if @goingForNot is true
        @goingForNot = false
        notNode = @createNotNode()
        notNode.nodes.push node
        return notNode
      return node

    @register 'str', (ast, cap) ->
      cap = cap[1..-2]
      # dealing with escaped strings
      tmpcap = cap
      cap = ""
      i = 0
      while i < tmpcap.length
        if tmpcap[i] is '\\'
          i++
          cap += tmpcap[i]
        else
          cap += tmpcap[i]
        ++i
      node = new Object
      node.type = 'text'
      node.repeat = '1'
      node.ast = null
      node.cap = null
      node.nodes = new Array
      node.nodes.push cap
      if @lastAst isnt null
        node.ast = @lastAst
        @lastAst = null
      if @lastCap isnt null
        if @capToField is true
          node.capField = true
          @capToField = false
        node.cap = @lastCap
        @lastCap = null
      if @goingForPeek is true
        @goingForPeek = false
        node.peek = true
      if @goingForNot is true
        @goingForNot = false
        notNode = @createNotNode()
        notNode.nodes.push node
        return notNode
      return node

    @register 'group', (ast) ->
      node = new Object
      node.type = 'undefined'
      node.repeat = '1'
      node.ast = null
      node.cap = null
      node.nodes = new Array
      if @lastAst isnt null
        node.ast = @lastAst
        @lastAst = null
      if @lastCap isnt null
        if @capToField is true
          node.capField = true
          @capToField = false
        node.cap = @lastCap
        @lastCap = null
      if @goingForPeek is true
        @goingForPeek = false
        node.peek = true
      if @goingForNot is true
        @goingForNot = false
        node.type = 'not'
      return node

    @register 'rule', (ast) ->
      return (ast) ->
        if ast.type is 'undefined'
          ast.type = 'and'
        return null

    @register 'peek', (ast) ->
      @goingForPeek = true
      return null

    @register 'closing_group', (ast) ->
      if ast.type is 'undefined'
        ast.type = 'and'
      return null

    @register 'repeater', (ast, cap) ->
      if ast.nodes.length < 1
        throw "Can't set repeater '#{cap}'"
      last = ast.nodes[-1..][0]
      if last.type is 'not'
        last = last.nodes[0]
      last.repeat = cap
      return null

    @register 'cap', (ast, cap) ->
      @lastCap = cap[..-2]
      return null

    @register 'capstr', (ast, cap) ->
      @lastCap = cap
      return null

    @register 'capfield', (ast, cap) ->
      if cap.length is 1
        @capToField = true
      else
        @capToField = false
      return null

    @register 'ast', (ast, cap) ->
      @lastAst = cap[..-2]
      return null

    @register 'newrule', (ast) ->
      node = new Object
      node.name = 'nil'
      node.nodes = new Array
      return node

    @register 'rulename', (ast, name) ->
      ast.name = name
      return null

    @register 'rulecore', (ast, name) ->
      node = new Object
      node.type = 'undefined'
      node.repeat = '1'
      node.ast = null
      node.cap = null
      node.nodes = new Array
      return node

    @register 'keyword', (ast, keyword) ->
      node = new Object
      node.type = keyword
      node.repeat = '1'
      node.ast = null
      node.cap = null
      node.nodes = new Array
      if @lastAst isnt null
        node.ast = @lastAst
        @lastAst = null
      if @lastCap isnt null
        if @capToField is true
          node.capField = true
          @capToField = false
        node.cap = @lastCap
        @lastCap = null
      if @goingForPeek is true
        @goingForPeek = false
        node.peek = true
      if @goingForNot is true
        @goingForNot = false
        notNode = @createNotNode()
        notNode.nodes.push node
        return notNode
      return node


class YParser extends AstParser
  constructor: -> super()

YParser.SimpleParser = SimpleParser
YParser.ExtendedParser = ExtendedParser
YParser.AstParser = AstParser
YParser.GrammarParser = GrammarParser
module.exports = YParser

