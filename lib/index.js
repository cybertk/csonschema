(function() {
  var CSON, DIR, fs, parse, parseSync, path, _, _normalize_path, _parseArray, _parseCustomizedType, _parseDefs, _parseField, _parseFromObj, _parseInclude, _parseObj, _parseRequired, _parseString,
    __slice = [].slice;

  fs = require('fs');

  CSON = require('cson-safe');

  _ = require('underscore');

  path = require('path');

  DIR = '';

  _normalize_path = function(filename, basedir) {
    if (filename.charAt(0) === '/') {
      return filename;
    } else {
      return path.join(basedir, filename);
    }
  };

  _parseCustomizedType = function(type, defs) {
    var t0, t1, _ref, _ref1;
    _ref = type.split('.'), t0 = _ref[0], t1 = 2 <= _ref.length ? __slice.call(_ref, 1) : [];
    if ((defs != null ? (_ref1 = defs.properties) != null ? _ref1[t0] : void 0 : void 0) == null) {
      throw new Error("Type is not defined: " + type);
    }
    if (t1.length > 0) {
      return _parseCustomizedType(t1.join('.'), defs.properties[t0]);
    } else {
      return defs.properties[t0];
    }
  };

  _parseField = function(source, defs) {
    if (_.isArray(source)) {
      return _parseArray(source, defs);
    } else if (_.isObject(source)) {
      if (source.$raw) {
        return source.$raw;
      }
      return _parseObj(source, defs);
    } else if (_.isString(source)) {
      return _parseString(source, defs);
    } else {
      throw Error("Syntax error, does not support '" + (typeof source) + "'field");
    }
  };

  _parseArray = function(array, defs) {
    if (array.length > 1) {
      return {
        "enum": array
      };
    }
    return {
      type: 'array',
      items: _parseField(array[0], defs)
    };
  };

  _parseObj = function(source, defs) {
    var k, obj, properties, v;
    obj = {};
    obj['type'] = 'object';
    properties = obj['properties'] = {};
    obj['required'] = _parseRequired(source);
    for (k in source) {
      v = source[k];
      if (k !== '$required') {
        properties[k] = _parseField(v, defs);
      }
    }
    obj['additionalProperties'] = false;
    return obj;
  };

  _parseRequired = function(source) {
    var field, item, items, k, requires, unrequires, v, _i, _j, _len, _len1, _ref, _ref1;
    requires = [];
    unrequires = [];
    if (_.has(source, '$required')) {
      if (!_.isString(source.$required)) {
        throw new Error('$required should be string');
      }
      if (!source.$required) {
        return [];
      }
      _ref = source.$required.split(' ');
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        field = _ref[_i];
        if (field.substring(0, 1) === '-') {
          unrequires.push(field.substring(1));
        } else {
          requires.push(field);
        }
      }
    }
    if (requires.length > 0 && unrequires.length > 0) {
      throw new Error('Should not mix required and unrequired');
    }
    items = (function() {
      var _results;
      _results = [];
      for (k in source) {
        v = source[k];
        if (k !== '$required') {
          _results.push(k);
        }
      }
      return _results;
    })();
    _ref1 = _.union(requires, unrequires);
    for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
      item = _ref1[_j];
      if (_.indexOf(items, item) === -1) {
        throw new Error("Required non-exist field: " + item);
      }
    }
    if (requires.length) {
      return requires;
    }
    return _.difference(items, unrequires);
  };

  _parseString = function(source, defs) {
    var _ref, _ref1, _ref2;
    switch (source) {
      case 'string':
      case 'integer':
      case 'number':
      case 'boolean':
        return {
          type: source
        };
      case 'date':
        return {
          type: 'string',
          format: 'date-time'
        };
      case 'email':
      case 'uri':
        return {
          type: 'string',
          format: source
        };
      default:
        if ((defs != null ? (_ref = defs.properties) != null ? (_ref1 = _ref.$_) != null ? (_ref2 = _ref1.properties) != null ? _ref2[source] : void 0 : void 0 : void 0 : void 0) != null) {
          return defs.properties.$_.properties[source];
        }
        return _parseCustomizedType(source, defs);
    }
  };

  _parseDefs = function(obj, defs) {
    var k, v;
    if (!_.isObject(obj)) {
      return;
    }
    if (defs == null) {
      defs = {};
    }
    if (_.isArray(obj)) {
      obj = obj[0];
    }
    for (k in obj) {
      v = obj[k];
      _.extend(defs, _parseDefs(v));
    }
    if (obj.$defs) {
      _.extend(defs, obj.$defs);
    }
    delete obj.$defs;
    return defs;
  };

  _parseInclude = function(obj, dir) {
    var filename, k, _results;
    if (!_.isObject(obj)) {
      return;
    }
    if (_.isArray(obj)) {
      if (obj[0].$include) {
        filename = _normalize_path(obj[0].$include, dir);
        obj[0] = CSON.parse(fs.readFileSync(filename));
      }
      if (filename) {
        dir = path.dirname(filename);
      }
      return _parseInclude(obj[0], dir);
    } else {
      _results = [];
      for (k in obj) {
        if (obj[k].$include) {
          filename = _normalize_path(obj[k].$include, dir);
          obj[k] = CSON.parse(fs.readFileSync(filename));
        }
        if (filename) {
          _results.push(_parseInclude(obj[k], path.dirname(filename)));
        } else {
          _results.push(_parseInclude(obj[k], dir));
        }
      }
      return _results;
    }
  };

  _parseFromObj = function(obj, defs, pwd) {
    var jsonschema;
    if (pwd == null) {
      pwd = process.env.PWD;
    }
    obj = _.clone(obj);
    _parseInclude(obj, pwd);
    defs = _parseField(_parseDefs(obj, defs));
    jsonschema = _parseField(obj, defs);
    jsonschema['$schema'] = 'http://json-schema.org/draft-04/schema';
    return jsonschema;
  };

  parse = function(source, callback) {
    var defs, error;
    try {
      if (_.isString(source)) {
        source = CSON.parse(source);
      }
      if (!_.isObject(source)) {
        return callback(new Error('<source> should be object or string'));
      }
      defs = {};
      return callback(null, _parseFromObj(source, {
        $_: defs
      }));
    } catch (_error) {
      error = _error;
      return callback(error);
    }
  };

  parseSync = function(source, defs) {
    if (!(typeof source === 'string' || 'object')) {
      throw new Error('You must supply either file or obj as source.');
    }
    if (_.isString(defs)) {
      defs = {
        $_: CSON.parse(fs.readFileSync(defs))
      };
    }
    if (typeof source === 'string') {
      DIR = path.dirname(_normalize_path(source, process.env.PWD));
      source = CSON.parse(fs.readFileSync(source));
    }
    return _parseFromObj(source, defs, DIR);
  };

  module.exports.parse = parse;

  module.exports.parseSync = parseSync;

}).call(this);
