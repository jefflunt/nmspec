[ruby-lang]: https://www.ruby-lang.org/
[gdscript]: https://docs.godotengine.org/en/stable/getting_started/scripting/gdscript/gdscript_basics.html
[generals.io]: https://generals.io/

`nmspec` (network message specification) is a subset of YAML used to specify
the format of communication protocols between two sides of a network
connection.

As a starting point this gem will support network messengers in these two
languages:

* [Ruby 3.0.x][ruby-lang]
* [GDScript 3.4][gdscript]

Additional languages can be added if there is interest. If so, then I will move
the Ruby and GDScript code generators to their own gems, and encourage other
language contributors to build their own gems to support their output
languages.

# Basic example

* `demo/minimal.nmspec` contains a minimal example of an `.nmspec` file.
* `demo/base_types.nmspec` contains a messenger with a single protocol that
* `demo/generals.io.nmspec` contains a theoretical implementation of the
messaging required for a game of [generals.io][generals.io]

# Sample usage

```ruby
pp  Nmspec::V1.gen(
      {
        'spec' => IO.read('generals.io.nmspec'),
        'langs' => ['ruby']
      }
    )
```

# Main concepts

## Messenger

A `messenger` is the thing you're descripting in an .nmspec file. A `messenger`
has default support for reading and writing a number of numeric, string, and
array types.

## Types

Custom-named types are a convenience feature that allows you to provide a more
convenient name for a base type for your messaging protocols.

A `Messenger` has many types.

## Protocols

A `protocol` is a list of `messages` that pass between two `Messenger` peers. A
`Messenger` has many protocols.

## Messages

Messages are either read (`r`) or writes (`w`) of types over a network
connection. `Messages` also define logical names for parameters and returned data.

```

# `nmspec` format

`nmspec` is a subset of YAML. So, first and foremost, if your `.nmspec` file is
not valid YAML, then it's definitely not valid `nmspec`.

## Required keys:

A minimal `messenger`, with only a name and default types supported must include:

* `version` - which currently must be set to `1`
* `msgr` - the top-level key for naming and describing the messenger
  * `name` - the name of the messenger
  * `desc` - a description of the messenger

## Optional keys:

* `protos` - a name for the messaging protocol
  * `desc` - a description of the message
  * `msgs` - a list of messages in the protocol
* `types` - if your `.nmspec` file creates custom sub-types, then this is where
  you declare them
