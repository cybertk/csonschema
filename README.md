# csonschema

[![Build Status](http://img.shields.io/travis/cybertk/csonschema.svg?style=flat)](https://travis-ci.org/cybertk/csonschema)


Only support Jsonchema draft 4.

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
user:
  username: 'username'
  created_at: 'date'
  updated_at: 'date'

additionalProperties: true
required: [
  'username'
  'created_at'
]
```

#### Object Array

```yaml
[
  user: 'user'
]
```
