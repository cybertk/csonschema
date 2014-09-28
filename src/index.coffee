fs = require 'fs'
CSON = require 'cson-safe'
_ = require 'underscore'
path = require 'path'


DIR = process.env.PWD

_normalize_path = (filename, basedir) ->
  if filename.charAt(0) is '/'
    filename
  else
    path.join(basedir, filename)

_parseCustomizedType = (type, defs) ->
  [t0, t1...] = type.split '.'

  throw new Error("Does not support field with value '#{type}'") unless defs.properties?[t0]?

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

      # $include field
      # TODO(quanlong): Async this call
      return _parseField CSON.parse(fs.readFileSync _normalize_path(source.$include, DIR)), defs if source.$include

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
  if source.$required
    throw new Error('$required should be string') unless _.isString(source.$required)
    
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

    # Advanced fields
    when 'date'
      return type: 'string', format: 'date-time'

    else

      # Global $def
      return defs.properties.$_.properties[source] if defs.properties?.$_?.properties?[source]?

      # Cutomized $def
      _parseCustomizedType(source, defs)


_parseFromObj = (obj) ->
  obj = _.clone obj
  if obj.$defs
    defs = _parseField obj.$defs
    delete obj.$defs

  jsonschema = _parseField obj, defs
  jsonschema['$schema'] = 'http://json-schema.org/draft-04/schema'

  return jsonschema

parse = (source, callback) ->

  try
    switch typeof(source)
      when 'string'
        DIR = path.dirname _normalize_path(source, DIR)
        # CSON.parseFile does not support customized file extension, see https://github.com/bevry/cson/issues/49
        fs.readFile source, (err, data) ->
          return callback(err) if err
          callback(null, _parseFromObj(CSON.parse data))

      when 'object'
        callback(null, _parseFromObj(source))
      else
        callback(new Error('You must supply either file or obj as source.'))

  catch error
    callback(error)

parseSync = (source) ->
  switch typeof(source)
    when 'string'
      DIR = path.dirname _normalize_path(source, DIR)
      data = fs.readFileSync source
      _parseFromObj(CSON.parse data)
    when 'object'
      _parseFromObj source
    else
      throw new Error('You must supply either file or obj as source.')


module.exports.parse = parse
module.exports.parseSync = parseSync
