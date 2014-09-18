
# http://coffeescriptcookbook.com/chapters/arrays/check-type-is-array
typeIsArray = Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'

_traverse = (source) ->

  # Object
  obj = {}
  obj['type'] = 'object'
  properties = obj['properties'] = {}

  # see http://spacetelescope.github.io/understanding-json-schema/reference/type.html#type
  for k, v of source
    properties[k] =
      switch v
        when 'string', 'integer', 'boolean' then type: v
        when 'date' then type: 'string', format: 'date-time'
        else
          if typeIsArray v
            enum: v
          else
            _traverse v

  obj['additionalProperties'] = false
  obj


parse = (source, callback) ->
  console.log('hi', callback)

  jsonschema = _traverse source
  jsonschema['$schema'] = 'http://json-schema.org/draft-04/schema'

  callback(null, jsonschema)

module.exports.parse = parse
