## csonschema

Write jsonschema with cson


[![Build Status](http://img.shields.io/travis/cybertk/csonschema.svg?style=flat)](https://travis-ci.org/cybertk/csonschema)
[![Dependency Status](https://david-dm.org/cybertk/csonschema.png)](https://david-dm.org/cybertk/csonschema)
[![Coverage Status](https://coveralls.io/repos/cybertk/csonschema/badge.png?branch=master)](https://coveralls.io/r/cybertk/csonschema?branch=master)

## Features

Only support Jsonchema draft 4.

### Simple csonschema

```coffee
username: 'string'
age: 'integer'
verified: 'boolean'
gender: ['F', 'M']
created_at: 'date'
```

### Advanced csonschema

```
$defs
  user:
    $include: "user.schema"
  tag:
    $raw:
      type: 'string'
      pattern: '^(\\([0-9]{3}\\))?[0-9]{3}-[0-9]{4}$'
  count:
    $raw:
      type: 'integer'
      minimum: 1
      maximum: 100

# Define a media object
owner: 'user'
tags: ['tag']
tag_count: 'count'
desc: 'string'
created_at: 'date'
```

## Installation

[Node.js][] and [NPM][] is required.

    $ npm install csonschema

[Node.js]: https://npmjs.org/
[NPM]: https://npmjs.org/

## Usage

### CLI

    $ csonschema schema.cson

### As lib in code

```
// Include csonschema
schema = require('csonschema');

// Parse a file path
schema.parse('data.cson', function(err,obj){});  // async

// Parse a String
schema.parse(src, function(err,obj){});  // async

// Synchronize Parse
obj = schema.parseSync(src);  // sync
```

#### Raw Field

Raw Field will be translated to json format directly without any modification, it is represented with `$raw` keyword.

```yaml

username:
  $raw:
    type: 'string'
    pattern: '[1-9a-zA-Z]'

date:
  $raw:
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
  $required: '-username -created_at'
```

#### Array Field

Array as root object

```yaml
[
  user: 'user'
]
```

Array in field

```yaml
username: 'string'
photos: [
  url: 'string'
]
```

## Contribution

## Run Tests

    $ npm test

Any contribution is more then welcome!
