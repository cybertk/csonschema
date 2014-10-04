fs = require 'fs'
CSON = require 'cson-safe'
_ = require 'underscore'
path = require 'path'

DIR = ''

_normalize_path = (filename, basedir) ->
  if filename.charAt(0) is '/'
    filename
  else
    path.join(basedir, filename)

_parseCustomizedType = (type, defs) ->
  [t0, t1...] = type.split '.'

  throw new Error("Type is not defined: #{type}") unless defs?.properties?[t0]?

  if t1.length > 0
    _parseCustomizedType(t1.join('.'), defs.properties[t0])
  else
    defs.properties[t0]

_parseField = (source, defs) ->
  if _.isArray source
    return _parseArray source, defs

  else if _.isObject source
      # $raw field
      return source.$raw if source.$raw

      # Object field
      return _parseObj source, defs

  else if _.isString source
    return _parseString source, defs
  else
    throw Error("Syntax error, does not support '#{typeof source}'field")

_parseArray = (array, defs) ->
  # Enum field
  return enum: array if array.length > 1

  {
    type: 'array'
    items: _parseField array[0], defs
  }

_parseObj = (source, defs) ->
  # Object
  obj = {}
  obj['type'] = 'object'
  properties = obj['properties'] = {}

  # required
  obj['required'] = _parseRequired source

  # see http://spacetelescope.github.io/understanding-json-schema/reference/type.html#type
  for k, v of source
    properties[k] = _parseField v, defs unless k is'$required'

  obj['additionalProperties'] = false
  obj


_parseRequired = (source) ->

  requires = []
  unrequires = []

  # Fill requires and unrequires array
  if _.has source, '$required'
    throw new Error('$required should be string') unless _.isString(source.$required)

    return [] unless source.$required

    for field in source.$required.split ' '
      if field.substring(0, 1) is '-'
        unrequires.push field.substring(1)
      else
        requires.push field


  if requires.length > 0 and unrequires.length > 0
    throw new Error('Should not mix required and unrequired')

  items = (k for k, v of source when k isnt '$required')
  for item in _.union(requires, unrequires)
    throw new Error("Required non-exist field: #{item}") if _.indexOf(items, item) is -1

  # Requires
  return requires if requires.length

  # Unrequires
  _.difference(items, unrequires)


_parseString = (source, defs) ->
  switch source
    # Basic fields
    when 'string', 'integer', 'number', 'boolean'
      return type: source

    # See http://spacetelescope.github.io/understanding-json-schema/reference/string.html
    # Jsonschema draft 4 built-in format
    when 'date'
      return type: 'string', format: 'date-time'
    when 'email', 'uri'
      return type: 'string', format: source

    else

      # Global $def
      return defs.properties.$_.properties[source] if defs?.properties?.$_?.properties?[source]?

      # Cutomized $def
      _parseCustomizedType(source, defs)


_parseDefs = (obj, defs) ->
  return unless _.isObject(obj)

  defs ?= {}

  # For array
  obj = obj[0] if _.isArray(obj)

  # Fill defs
  _.extend(defs, _parseDefs v) for k, v of obj
  _.extend(defs, obj.$defs) if obj.$defs

  delete obj.$defs
  defs

_parseInclude = (obj, dir) ->
  return unless _.isObject(obj)

  if _.isArray(obj)

    if obj[0].$include
      filename = _normalize_path(obj[0].$include, dir)
      obj[0] = CSON.parse(fs.readFileSync filename)

    dir = path.dirname filename if filename
    _parseInclude obj[0], dir

  else

    for k of obj
      if obj[k].$include
        filename = _normalize_path(obj[k].$include, dir)
        obj[k] = CSON.parse(fs.readFileSync filename)

      if filename
        _parseInclude obj[k], path.dirname filename
      else
        _parseInclude obj[k], dir


_parseFromObj = (obj, defs, pwd = process.env.PWD) ->
  obj = _.clone obj

  _parseInclude obj, pwd

  defs = _parseField _parseDefs(obj, defs)

  jsonschema = _parseField obj, defs
  jsonschema['$schema'] = 'http://json-schema.org/draft-04/schema'

  return jsonschema

parse = (source, callback) ->

  try
    source = CSON.parse source if _.isString(source)
    return callback(new Error('<source> should be object or string')) unless _.isObject(source)

    # Global defs
    # defs = CSON.parse source if _.isString(defs)
    # return callback(new Error('<defs> should be object or string')) unless _.isObject(defs)
    defs = {}

    callback(null, _parseFromObj source, {$_: defs})
  catch error
    callback(error)


parseSync = (source, defs) ->
  throw new Error('You must supply either file or obj as source.') unless typeof(source) is 'string' or 'object'

  # Global defs
  defs = {$_: CSON.parse fs.readFileSync(defs)} if _.isString(defs)

  if typeof(source) is 'string'
    DIR = path.dirname _normalize_path(source, process.env.PWD)
    source = CSON.parse fs.readFileSync(source)

  _parseFromObj source, defs, DIR


module.exports.parse = parse
module.exports.parseSync = parseSync
