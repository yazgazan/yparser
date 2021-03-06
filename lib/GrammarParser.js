// Generated by CoffeeScript 1.7.1
(function() {
  var DefaultHooks, GrammarParser, YParser,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  DefaultHooks = require('./DefaultHooks');

  YParser = require('./YParser');

  GrammarParser = (function(_super) {
    __extends(GrammarParser, _super);

    function GrammarParser(_tokenRules, _rules) {
      this._tokenRules = _tokenRules != null ? _tokenRules : {};
      this._rules = _rules != null ? _rules : {};
      GrammarParser.__super__.constructor.call(this);
      this.setupTokens();
      this.setupRules();
      this.setupBuiltins();
      this.tokenStack = [];
      this.ruleStack = [];
    }

    GrammarParser.prototype.loadJson = function(json) {
      var obj;
      obj = JSON.parse(json);
      this._tokenRules = obj._tokenRules;
      this._rules = obj._rules;
      this.setupTokens();
      return this.setupRules();
    };

    GrammarParser.prototype.setupTokens = function() {
      var name, token, _ref, _results;
      _ref = this._tokenRules;
      _results = [];
      for (name in _ref) {
        token = _ref[name];
        _results.push(((function(_this) {
          return function(name) {
            return _this.addTokRule(name, function() {
              return _this.execToken(name);
            });
          };
        })(this))(name));
      }
      return _results;
    };

    GrammarParser.prototype.setupRules = function() {
      var name, rule, _ref, _results;
      _ref = this._rules;
      _results = [];
      for (name in _ref) {
        rule = _ref[name];
        _results.push(((function(_this) {
          return function(name) {
            return _this.addRule(name, function(ast) {
              return _this.execRule(name, ast);
            });
          };
        })(this))(name));
      }
      return _results;
    };

    GrammarParser.prototype.setupBuiltins = function() {
      this.builtins = {
        space: function() {
          return this.readSpaces();
        },
        spaces: function() {
          return this.readSpaces();
        },
        anyspace: function() {
          return this.readSpace() || this.readEOL();
        },
        anyspaces: function() {
          return this.repeat("+", function() {
            return this.readSpaces() || this.readEOL();
          });
        },
        eol: function() {
          return this.readEOL();
        },
        eof: function() {
          return this.readEOF();
        },
        alpha: function() {
          return this.readAlpha();
        },
        num: function() {
          return this.readNum();
        },
        alphanum: function() {
          return this.readAlphaNum();
        },
        int: function() {
          return this.readInt();
        },
        id: function() {
          return this.readIdentifier();
        },
        any: function() {
          return this.readAny();
        },
        all: function() {
          return this.readAll();
        }
      };
      return this.builtinsRules = {
        eof: function() {
          return this.isEndToken();
        },
        "false": function() {
          return false;
        },
        "true": function() {
          return true;
        }
      };
    };

    GrammarParser.prototype.execAnd = function(nodes, cb, ast) {
      var node, _i, _len;
      for (_i = 0, _len = nodes.length; _i < _len; _i++) {
        node = nodes[_i];
        if (!(this.handle((function(_this) {
          return function() {
            return cb.call(_this, node, ast);
          };
        })(this)))) {
          return false;
        }
      }
      return true;
    };

    GrammarParser.prototype.execOr = function(nodes, cb, ast) {
      var backupCPos, backupLine, backupPos, node, _i, _j, _len, _len1;
      backupPos = this.pos;
      backupCPos = this.cpos;
      backupLine = this.line;
      for (_i = 0, _len = nodes.length; _i < _len; _i++) {
        node = nodes[_i];
        if (node.type !== "not") {
          continue;
        }
        if (cb.call(this, node, ast)) {
          this.pos = backupPos;
          this.cpos = backupCPos;
          this.line = backupLine;
          return false;
        }
      }
      this.pos = backupPos;
      this.cpos = backupCPos;
      this.line = backupLine;
      for (_j = 0, _len1 = nodes.length; _j < _len1; _j++) {
        node = nodes[_j];
        if (node.type === "not") {
          continue;
        }
        if (this.handle((function(_this) {
          return function() {
            return cb.call(_this, node, ast);
          };
        })(this))) {
          return true;
        }
      }
      return false;
    };

    GrammarParser.prototype.execRule = function(name, ast) {
      var ret;
      if (this._rules[name] != null) {
        ret = this.handleNode(this._rules[name], ast);
        return ret;
      }
      if (this._tokenRules[name] != null) {
        return this.readToken(name);
      }
      if (this.builtinsRules[name] != null) {
        return this.builtinsRules[name].call(this);
      }
      throw Error("unkown rule '" + name + "'.");
    };

    GrammarParser.prototype.handleNode = function(node, ast) {
      var cap, curAst, curCap, func, newTok, ret;
      curAst = ast;
      curCap = null;
      if (node.ast !== null) {
        curAst = new YParser.Ast(node.ast);
      }
      if (node.cap !== null) {
        curCap = this.curToken;
      }
      ret = this.execRuleNode(node, curAst);
      if (ret === false) {
        return false;
      }
      if (node.ast !== null) {
        if (node.hook !== null) {
          func = null;
          if (this[node.hook] != null) {
            func = this[node.hook];
          } else {
            func = this.findFunc(node.hook);
          }
          if (func === null) {
            throw Error("couldn't find hook '" + node.hook + "'");
          }
          func.call(this, curAst);
        }
        ast.nodes.push(curAst);
      }
      if (node.cap !== null) {
        cap = this.capture(curCap);
        if (node.hook !== null) {
          if (this[node.hook] != null) {
            cap = this[node.hook].call(this, cap);
          } else {
            func = this.findFunc(node.hook);
            if (func !== null) {
              cap = func.call(this, cap);
            } else {
              throw Error("couldn't find hook '" + node.hook + "'");
            }
          }
        }
        if (node.toField === false) {
          newTok = ast.addToken(this.tokens[curCap]);
          newTok.type = node.data;
          newTok.data = cap;
        } else {
          ast[node.cap] = cap;
        }
      }
      return true;
    };

    GrammarParser.prototype.findFunc = function(name, obj) {
      if (obj == null) {
        obj = this.constructor;
      }
      if (obj[name] != null) {
        return obj[name];
      }
      if (obj.__super__) {
        return this.findFunc(name, obj.__super__.constructor);
      }
      return null;
    };

    GrammarParser.prototype.capture = function(startToken) {
      var i, ret, _i, _ref;
      ret = "";
      for (i = _i = startToken, _ref = this.curToken; startToken <= _ref ? _i < _ref : _i > _ref; i = startToken <= _ref ? ++_i : --_i) {
        ret += this.tokens[i].data;
      }
      return ret;
    };

    GrammarParser.prototype.execRuleNode = function(node, ast) {
      var ret, _backupPos;
      _backupPos = this.curToken;
      ret = this.repeat(node.repeat, (function(_this) {
        return function() {
          var backupPos;
          if (node.type === "and") {
            return _this.execAnd(node.nodes, _this.handleNode, ast);
          }
          if (node.type === "or") {
            return _this.execOr(node.nodes, _this.handleNode, ast);
          }
          if (node.type === "not") {
            backupPos = _this.curToken;
            ret = _this.handleNode(node.nodes[0], ast);
            _this.curToken = backupPos;
            return ret;
          }
          if (node.type === "ID") {
            return _this.execRule(node.data, ast);
          }
          if (node.type === "hook") {
            return _this.triggerHook(node.data, ast);
          }
          if (node.type === "debug") {
            console.log("DEBUG : " + node.data);
            return true;
          }
          throw Error("unknown type '" + node.type + "'");
        };
      })(this));
      if ((ret === false) && (node.orError === true)) {
        this.error();
      }
      if ((ret === false) || (node.peek === true)) {
        this.curToken = _backupPos;
      }
      return ret;
    };

    GrammarParser.prototype.triggerHook = function(name, ast) {
      var func;
      func = null;
      if (this[name] != null) {
        func = this[name];
      } else {
        func = this.findFunc(name);
      }
      if (func === null) {
        throw Error("couldn't find hook '" + name + "'");
      }
      return func.call(this, ast);
    };

    GrammarParser.prototype.execToken = function(name) {
      var ret;
      ret = null;
      if ((this.tokenStack.indexOf(name)) !== -1) {
        if (this.builtins[name] != null) {
          return this.builtins[name].call(this);
        }
        throw Error("unkown rule '" + name + "'");
      }
      this.tokenStack.push(name);
      if (this._tokenRules[name] != null) {
        ret = this.execTokenNode(this._tokenRules[name]);
      } else if (this.builtins[name] != null) {
        ret = this.builtins[name].call(this);
      }
      this.tokenStack.pop();
      return ret;
    };

    GrammarParser.prototype.execTokenNode = function(node) {
      var ret, _backupCPos, _backupLine, _backupPos;
      _backupPos = this.pos;
      _backupCPos = this.cpos;
      _backupLine = this.line;
      ret = this.repeat(node.repeat, (function(_this) {
        return function() {
          var backupCPos, backupLine, backupPos;
          if (node.type === "and") {
            return _this.execAnd(node.nodes, _this.execTokenNode);
          }
          if (node.type === "or") {
            return _this.execOr(node.nodes, _this.execTokenNode);
          }
          if (node.type === "not") {
            backupPos = _this.pos;
            backupCPos = _this.cpos;
            backupLine = _this.line;
            ret = _this.execTokenNode(node.nodes[0]);
            _this.pos = backupPos;
            _this.cpos = backupCPos;
            _this.line = backupLine;
            return ret;
          }
          if ((node.type === "STR") || (node.type === "STR_DBL")) {
            return _this.readText(node.data);
          }
          if (node.type === "ID") {
            if ((_this._tokenRules[node.data] != null) || (_this.builtins[node.data] != null)) {
              return _this.execToken(node.data);
            }
            throw Error("unkown rule '" + node.data + "'");
          }
          throw Error("unknown type '" + node.type + "'");
        };
      })(this));
      if (node.peek === true) {
        this.pos = _backupPos;
        this.cpos = _backupCPos;
        this.line = _backupLine;
      }
      return ret;
    };

    GrammarParser.prototype.handle = function(cb) {
      var backupCPos, backupLine, backupPos;
      backupPos = this.pos;
      backupCPos = this.cpos;
      backupLine = this.line;
      if (cb()) {
        return true;
      }
      this.pos = backupPos;
      this.cpos = backupCPos;
      this.line = backupLine;
      return false;
    };

    return GrammarParser;

  })(DefaultHooks);

  module.exports = GrammarParser;

}).call(this);
