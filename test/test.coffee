csonschema = require '..'
chai = require 'chai'

chai.should()

obj = ''

describe 'Parse', ->

  source = ''

  describe 'Simple 1 level schema', ->

    before (done) ->
      source =
        username: 'string'
        age: 'integer'
        verified: 'boolean'
        gender: ['F', 'M']
        created_at: 'date'

      csonschema.parse source, (err, _obj) ->
        obj = _obj
        done()

    it 'should be a jsonschema', ->
      obj.$schema.should.equal 'http://json-schema.org/draft-04/schema'

    it 'should be a object', ->
      obj.type.should.equal 'object'
      obj.properties.should.be.a 'object'

    it 'object should have correct string field', ->
      field = obj.properties.username
      field.type.should.equal 'string'

    it 'object should have correct integer field', ->
      field = obj.properties.age
      field.type.should.equal 'integer'

    it 'object should have correct boolean field', ->
      field = obj.properties.verified
      field.type.should.equal 'boolean'

    it 'object should have correct enum field', ->
      field = obj.properties.gender
      field.enum.should.have.length 2
      field.enum.should.include 'F'
      field.enum.should.include 'M'

    it 'object should have correct date field', ->
      field = obj.properties.created_at
      field.type.should.equal 'string'
      field.format.should.equal 'date-time'

    it 'object should not allow additional properties', ->
      obj.additionalProperties.should.not.ok


  describe 'Schema with customized types', ->

    before (done) ->
      source =
        $defs:
          created_at: 'date'
        created_at: 'created_at'

      csonschema.parse source, (err, _obj) ->
        console.log(_obj)
        obj = _obj
        done()

    it 'should use types defiend in $defs', ->
      obj.properties.created_at.type.should.equal 'string'
      obj.properties.created_at.format.should.equal 'date-time'


  describe 'Schema with embedded objects', ->

    before (done) ->
      source =
        user:
          username: 'string'
        config:
          user:
            verified: 'boolean'

      csonschema.parse source, (err, _obj) ->
        obj = _obj
        done()

    it 'should be a jsonschema', ->
      obj.$schema.should.equal 'http://json-schema.org/draft-04/schema'

    it 'should be a object', ->
      obj.type.should.equal 'object'
      obj.properties.should.be.a 'object'

    it 'object should have level-1 embedded object', ->
      field = obj.properties.user
      field.type.should.equal 'object'

      subfield = field.properties.username
      subfield.type.should.equal 'string'

    it 'object should have level-2 embedded object', ->
      field = obj.properties.config.properties.user
      field.type.should.equal 'object'

      subfield = field.properties.verified
      subfield.type.should.equal 'boolean'
