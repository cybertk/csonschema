csonschema = require '..'
chai = require 'chai'
fs = require 'fs'
tmp = require 'tmp'

chai.should()

obj = ''

describe 'Parse Async', ->

  source = ''

  describe 'Simple 1 level schema', ->

    before (done) ->
      source =
        username: 'string'
        age: 'integer'
        verified: 'boolean'
        gender: ['F', 'M']
        weight: 'number'
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

    it 'object should have correct number field', ->
      field = obj.properties.weight
      field.type.should.equal 'number'

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

  describe 'Schema with array', ->

    describe 'as root schema', ->
      before (done) ->
        source =
          [
            w: 'integer'
            h: 'integer'
          ]

        csonschema.parse source, (err, _obj) ->
          return done(err) if err
          obj = _obj
          done()

      it 'root object should be array', ->
        obj.type.should.equal 'array'

      it 'should have correct object in array items', ->
        item = obj.items
        item.type.should.equal 'object'
        item.properties.w.type.should.equal 'integer'
        item.properties.h.type.should.equal 'integer'

    describe 'as array field', ->
      describe 'contains object', ->

        before (done) ->
          source =
            photos: [
              w: 'integer'
              h: 'integer'
            ]

          csonschema.parse source, (err, _obj) ->
            obj = _obj
            done()

        it 'should have correct array field', ->
          field = obj.properties.photos
          field.type.should.equal 'array'

        it 'should have correct object in array items', ->
          item = obj.properties.photos.items
          item.type.should.equal 'object'
          item.properties.w.type.should.equal 'integer'
          item.properties.h.type.should.equal 'integer'

      describe 'contains simple types', ->

        before (done) ->
          source =
            foos: [ 'string' ]

          csonschema.parse source, (err, _obj) ->
            obj = _obj
            done()

        it 'should have correct array field', ->
          field = obj.properties.foos
          field.type.should.equal 'array'

        it 'should have correct object in array items', ->
          item = obj.properties.foos.items
          item.type.should.equal 'string'

      describe 'contains $defs types', ->

        before (done) ->
          source =
            $defs:
              foo: 'string'
            foos: [ 'foo' ]

          csonschema.parse source, (err, _obj) ->
            obj = _obj
            done()

        it 'should have correct array field', ->
          field = obj.properties.foos
          field.type.should.equal 'array'

        it 'should have correct object in array items', ->
          item = obj.properties.foos.items
          item.type.should.equal 'string'

  describe 'Schema with $defs', ->

    describe 'contains simple type', ->

      before (done) ->
        source =
          $defs:
            created_at: 'date'
          created_at: 'created_at'

        csonschema.parse source, (err, _obj) ->
          obj = _obj
          done()

      it 'should use types defiend in $defs', ->
        obj.properties.created_at.type.should.equal 'string'
        obj.properties.created_at.format.should.equal 'date-time'

    describe 'contains cascading type', ->

      before (done) ->
        source =
          $defs:
            foo:
              bar:
                koo: 'date'
          created_at: 'foo.bar.koo'

        csonschema.parse source, (err, _obj) ->
          obj = _obj
          done()

      it 'should use types defiend in $defs', ->
        obj.properties.created_at.type.should.equal 'string'
        obj.properties.created_at.format.should.equal 'date-time'

    describe 'contains global type', ->

      before (done) ->
        source =
          $defs:
            $_:
              bar: 'date'
          updated_at: '$_.bar'
          created_at: 'bar'

        csonschema.parse source, (err, _obj) ->
          obj = _obj
          done()

      it 'should use types defiend in $defs', ->
        obj.properties.updated_at.type.should.equal 'string'
        obj.properties.updated_at.format.should.equal 'date-time'

      it 'should use cascading type defiend in $defs', ->
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

  describe 'Schema with $required', ->

    describe 'implicit required', ->

      before (done) ->
        source =
          username: 'string'
          age: 'integer'
          verified: 'boolean'

        csonschema.parse source, (err, _obj) ->
          obj = _obj
          done()

      it 'all fields should be required', ->
        obj.required.should.have.length 3
        obj.required.should.include 'username'
        obj.required.should.include 'age'
        obj.required.should.include 'verified'


    describe 'and required fields explicitly', ->

      before (done) ->
        source =
          username: 'string'
          age: 'integer'
          verified: 'boolean'
          $required: 'age username'

        csonschema.parse source, (err, _obj) ->
          obj = _obj
          done()

      it 'should only required explicit field', ->
        obj.required.should.have.length 2
        obj.required.should.include 'age'
        obj.required.should.include 'username'


    describe 'and do not required fields explicitly', ->

      before (done) ->
        source =
          username: 'string'
          age: 'integer'
          verified: 'boolean'
          $required: '-age -username'

        csonschema.parse source, (err, _obj) ->
          obj = _obj
          done()

      it 'should not required explicit un-required field', ->
        obj.required.should.have.length 1
        obj.required.should.include 'verified'

  describe 'Schema with $raw', ->

    source = ''

    describe 'as simple field', ->

      before (done) ->
        source =
          username:
            $raw:
              type: 'string'
              minLength: 1
              maxLength: 10

        csonschema.parse source, (err, _obj) ->
          obj = _obj
          done()

      it 'should be a object', ->
        obj.type.should.equal 'object'
        obj.properties.should.be.a 'object'

      it 'should expand $raw field', ->
        obj.properties.username.should.equal source.username.$raw


    describe 'contains in $defs field', ->

      before (done) ->
        source =
          $defs:
            username:
              $raw:
                type: 'string'
                minLength: 1
                maxLength: 10
          u: 'username'

        csonschema.parse source, (err, _obj) ->
          obj = _obj
          done()

      it 'should be a object', ->
        obj.type.should.equal 'object'
        obj.properties.should.be.a 'object'

      it 'should expand $raw field', ->
        obj.properties.u.should.deep.equal source.$defs.username.$raw


  describe 'Schema with $include', ->

    include = ''

    describe 'as simple field', ->

      before (done) ->
        include = """
                  username: 'string'
                  age: 'integer'
                  """

        tmp.file (err, path, fd) ->
          return done(err) if err

          fs.writeFileSync(path, include)
          source =
            user:
              $include: path

          csonschema.parse source, (err, _obj) ->
            obj = _obj
            done()

      it 'should be a object', ->
        obj.type.should.equal 'object'
        obj.properties.should.be.a 'object'

      it 'should expand $include field', ->
        field =  obj.properties.user
        field.type.should.equal 'object'
        field.properties.username.type.should.equal 'string'
        field.properties.age.type.should.equal 'integer'


  describe 'From file', ->

    describe 'with simple schema', ->
      before (done) ->
        csonschema.parse "#{__dirname}/fixtures/sample1.schema", (err, _obj) ->
          obj = _obj
          done()

      it 'should be a object', ->
        obj.type.should.equal 'object'
        obj.properties.should.be.a 'object'

    describe 'with schema contains $include', ->
      before (done) ->
        csonschema.parse "#{__dirname}/fixtures/sample2.schema", (err, _obj) ->
          obj = _obj
          done()

      it 'should be a object', ->
        obj.type.should.equal 'object'
        obj.properties.should.be.a 'object'

describe 'Parse Sync', ->

  source = ''

  describe 'Simple schema', ->

    before ->
      source =
        username: 'string'

      obj = csonschema.parseSync source

    it 'should be a jsonschema', ->
      obj.$schema.should.equal 'http://json-schema.org/draft-04/schema'
