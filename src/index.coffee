
# http://coffeescriptcookbook.com/chapters/arrays/check-type-is-array
typeIsArray = Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'


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
          if typeIsArray v
            enum: v
          else if 'string' == typeof v
            defs.properties[v]
          else
            _traverse v, defs

  obj['additionalProperties'] = false
  obj


parse = (source, callback) ->

  if source.$defs
    defs = _traverse source.$defs
    delete source.$defs

  jsonschema = _traverse source, defs
  jsonschema['$schema'] = 'http://json-schema.org/draft-04/schema'

  callback(null, jsonschema)

module.exports.parse = parse
