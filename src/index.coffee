fs = require 'fs'
CSON = require 'cson-safe'
_ = require 'underscore'


_traverse = (source, defs) ->

  # Object
  obj = {}
  obj['type'] = 'object'
  properties = obj['properties'] = {}

  # required
  required = source.$required
  delete source.$required

  obj['required'] = (k for k, v of source)
  if required

    required = required.replace /^\s+/g, ""

    if required.substring(0,1) != '-'
      obj.required = []

    for field in required.split ' '
      if field.substring(0, 1) == '-'
        obj.required.splice(obj.required.indexOf(field.substring(1)), 1)
      else
        obj.required.push(field)


  # see http://spacetelescope.github.io/understanding-json-schema/reference/type.html#type
  for k, v of source
    properties[k] =
      switch v
        when 'string', 'integer', 'boolean' then type: v
        when 'date' then type: 'string', format: 'date-time'
        else
          if _.isArray v
            if v.length > 1
              enum: v
            else

              # Object in array, i.e [ { foo: 'bar' } ]
              if _.isObject v[0]
                {
                  type: 'array'
                  items: _traverse v[0], defs
                }
              # Simple type in array, i.e. [ 'string' ]
              else
                {
                  type: 'array'
                  items:
                    type: v[0]
                }
          else if _.isString v
            defs.properties[v]
          else
            _traverse v, defs

  obj['additionalProperties'] = false
  obj


_parseFromObj = (obj, callback) ->
  if obj.$defs
    defs = _traverse obj.$defs
    delete obj.$defs

  if _.isArray obj
    jsonschema =
      type: 'array'
      items: _traverse obj[0], defs
  else
    jsonschema = _traverse obj, defs
  jsonschema['$schema'] = 'http://json-schema.org/draft-04/schema'

  callback(null, jsonschema)

parse = (source, callback) ->

  switch typeof(source)
    when 'string'
      # CSON.parseFile does not support customized file extension, see https://github.com/bevry/cson/issues/49
      fs.readFile source, (err, data) ->
        return callback(err) if err

        _parseFromObj (CSON.parse data), callback
    when 'object'
      _parseFromObj(source, callback)
    else
      callback(new Error('You must supply either file or obj as source.'))


module.exports.parse = parse
