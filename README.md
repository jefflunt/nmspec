
`nmspec` (network message specification) is a subset of YAML used to specify
the format of communication protocols between two sides of a network
connection.

As a starting point this gem will support network messengers in these two
languages:

* [Ruby 3.0.x][ruby-lang]
* [GDScript 3.4][gdscript]

Additional languages can be added if there is interest.

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

* `types` - if your `.nmspec` file creates custom sub-types, then this is where
  you declare them
* `protos` - the top-level key for the list of messaging protocols
  * for each protocol:
    * `name` - the name of the protocol (converted to function/method name)
    * `desc` - a description of the protocol
    * `msgs` - a list of messages in the protocol

## Sample `.nmspec` file

The `.nmspec` file, `demo/base_types.nmspec` is included for testing all base
types.

```yaml
version: 1

msgr:
  name: base types
  desc: this messenger only supports the built-in types, and has no custom messages

protos:
  - name: all_base_types
    desc: write all base types, then read them back
    msgs:
      # LEGEND: `m` is either 'w' (write) or 'r' (read)
      # m type        var name
      # ----------------------------------------------------
      - w i8          i8
      - w u8          u8
      - w i8_list     i8_list
      - w u8_list     u8_list
      - w i16         i16
      - w u16         u16
      - w i16_list    i16_list
      - w u16_list    u16_list
      - w i32         i32
      - w u32         u32
      - w i32_list    i32_list
      - w u32_list    u32_list
      - w i64         i64
      - w u64         u64
      - w i64_list    i64_list
      - w u64_list    u64_list
      - w float       float
      - w float_list  float_list
      - w double      double
      - w double_list double_list
      - w str         str
      - w str_list    str_list
```

  [ruby-lang]: https://www.ruby-lang.org/
  [gdscript]: https://docs.godotengine.org/en/stable/getting_started/scripting/gdscript/gdscript_basics.html
  [generals.io]: https://generals.io/
