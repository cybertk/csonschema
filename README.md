## csonschema

Write jsonschema with cson


[![Build Status](http://img.shields.io/travis/cybertk/csonschema.svg?style=flat)](https://travis-ci.org/cybertk/csonschema)
[![Dependency Status](https://david-dm.org/cybertk/csonschema.png)](https://david-dm.org/cybertk/csonschema)
[![Coverage Status](https://coveralls.io/repos/cybertk/csonschema/badge.png?branch=master)](https://coveralls.io/r/cybertk/csonschema?branch=master)

## Features

Only support Jsonchema draft 4.

## Installation

[Node.js][] and [NPM][] is required.

    $ npm install csonschema

[Node.js]: https://npmjs.org/
[NPM]: https://npmjs.org/

## Usage

### CLI

    $ csonschema schema.cson

### Code

```
  // Include csonschema
  schema = require('csonschema');

  // Parse a file path
  schema.parse('data.cson', function(err,obj){});  // async

  // Parse a String
  schema.parse(src, function(err,obj){});  // async

```

#### Types

Defined all types in single one types file and reuse them in all schemas

```yaml

username:
  type: 'string'
  pattern: '[1-9a-zA-Z]'

date:
  type: 'string'
  format: 'date-time'
```

#### Object

additionalProperties is false by default

```yaml

$defs:
  username: 'string'

user:
  username: 'username'
  created_at: 'date'
  updated_at: 'date'
```

#### Object Array

```yaml
[
  user: 'user'
]
```

## Contribution

## Run Tests

    $ npm test

Any contribution is more then welcome!
