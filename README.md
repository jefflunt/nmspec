# `nmspec`

`nmspec` (network message specification) is a combination of binary
serialization and network communication (basically [rpc][rpc]), designed to
make creating TCP protocols between two ends of a network connection easier to
specify and keep consistent..

A centralized YAML file is used to describe the types and messages passed
between network peers, and from that description TCP peer code (a "messenger")
is generated in any supported output programming language. The messages
described in `nmspec` are used to create both the reading and writing sides
of the connection, so that a single source code file contains everything you
need for a network peer, regardless of if it's the client or server.

## Motivation

`nmspec` was specifically created to help with with a problem I was facing,
where I was designing some network peers in two different programming languages
that needed to talk to each other, and I found that keeping the two sides in
sync generated a lot of bugs that I thought might be avoided by centralizing the
description of their communication protocols. Without this, what was happening
regularly was:

1. I would change something on the server side in one programming language
2. I would change the same thing on the client side in a different programming
   language
3. The serialization of data on one side of the network would get out of sync
   with the deserialization on the other side

By describing the wire protocol in one place it was my hope that I would reduce
the amount of time I spent on synchronization issues.

## Results

My approach to making this constantly-shifting communication easier to develop
and debug was to come up with a language-agnostic representation of the network
protocols within the game, specifically in some kind of easily editable
configuration language. YAML fits that description. I then integrated this
tightly with TCP (a decent starting point).

The code generators are written in Ruby, which is reasonably expressive for this
purpose.

# Output language support

As a starting point this gem supports network messengers in these two languages:

* [Ruby 3.x][ruby-lang]
* [GDScript 3.x.stable][gdscript]

`nmspec` came out of a online game project where the backend is written in
Ruby, and the frontend is built with the Godot game engine, which includes the
embedded scripting language, GDSCript.

# Sample usage

```ruby
# add 'nmspec' to your Gemfile

$ irb

 > require 'nmspec'
=> true
 > pp  Nmspec::V1.gen({
         'spec' => IO.read('generals.io.nmspec'),
         'langs' => ['ruby', 'gdscript']
       })
=> {
     "valid"=>true,
     "errors"=>[],
     "warnings"=>[],
     "code"=> {
       "ruby"=> "< a string of generated Ruby code that you can save to a file>",
       "gdscript"=> "< a string of generated GDSCript code that you can save to a file>",
     }
   }
```

# Main concepts

## Messenger

A `messenger` is the thing you're descripting in an .nmspec file. A `messenger`
has default support for reading and writing a number of numeric, string, and
array types.

## Built-in types

The following built-in types are supported by `nmspec`

```plaintext
bool                        # boolean true/false
i8  u8  i8_list  u8_list    # signed/unsigned 8-bit ints, and lists of the same
i16 u16 i16_list u16_list   # signed/unsigned 16-bit ints, and lists of the same
i32 u32 i32_list u32_list   # signed/unsigned 32-bit ints, and lists of the same
i64 u64 i64_list u64_list   # signed/unsigned 64-bit ints, and lists of the same
float   float_list          # signed single-precision 32-bit floating point numbers, and a list of the same
double  double_list         # signed double-precision 64-bit floating point numbers, and a list of the same
str     str_list            # strings (arrays of bytes)
```

As of this writing, all types are sent with big-endian encoding.

`*_list` types are ordered lists of elements (i.e. arrays).

There is no support for mixed-type list, mostly because socket libraries seem to
be centered around efficiently encoding/decoding streams of bytes with known bit
widths. If you want to send multiple data types one after the other, place them
into separate messages (see examples below).

## Custom types

Custom types are a way for you to give a more domain-relevant name to the
built-in types. Custom types are not structs, nor are they similar to classes
from object-oriented programming. You could, however, write your own structs or
object classes to wrap the reading/writing of protocols, if you like, but that
would be extra work that you would need to do in your own program code.

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
  * `bigendian` - (optional, defaults to `true`)
    * if `true`, communication uses big-endian byte order
    * if `false`, communication uses little-endian
  * `nodelay` - (optional, defaults to `false`)
    * if `true`, disables Nagle's algorithm, which prioritizes low-latency over
      throughput efficiency
    * if `false`, leaves Nagle's algorithm enabled

## Optional keys:

* `types` - if your `.nmspec` file creates custom sub-types, then this is where
  you declare them
* `protos` - the top-level key for the list of messaging protocols
  * for each protocol:
    * `name` - the name of the protocol (converted to function/method name)
    * `desc` - a description of the protocol
    * `msgs` - a list of messages in the protocol

## Sample `.nmspec` file

`demo/minimal.nmspec` shows the absolute minimum amount of information needed
to get a basic messenger working.

```yaml
version: 1

msgr:
  name: minimal
  desc: this messenger only supports the built-in types, and has no custom protocols
```

`demo/base_types.nmspec` shows an example of a one-protocol messenger that is
used to ensure that all base types can be read and written correctly.

```yaml
version: 1

msgr:
  name: base types
  desc: this messenger supports the built-in types, and is mainly used for testing code generators
  nodelay: true
  bigendian: false

protos:
  - name: all_base_types
    desc: write all base types
    msgs:
      # type        var name
      # ----------------------------------------------------
      - bool        bool
      - i8          i8
      - u8          u8
      - i8_list     i8_list
      - u8_list     u8_list
      - i16         i16
      - u16         u16
      - i16_list    i16_list
      - u16_list    u16_list
      - i32         i32
      - u32         u32
      - i32_list    i32_list
      - u32_list    u32_list
      - i64         i64
      - u64         u64
      - i64_list    i64_list
      - u64_list    u64_list
      - float       float
      - float_list  float_list
      - double      double
      - double_list double_list
      - str         str
      - str_list    str_list
```

`demo/generals.io.nmspec` contains a theoretical implementation of a messenger
for the game, [generals.io][generals.io]:

```yaml
version: 1

msgr:
  name: generals.io
  desc: demo nmspec file for generals.io

types:
  - u8  player_id
  - u8  serv_code
  - str serv_msg
  - u16 tile_id
  - u8  terrain

protos:
  - name: set_player_name
    desc: client message sets the player name for a given player
    msgs:
      - str player_name
  - name: resp_player_name
    desc: server message to accept or reject the player name
    msgs:
      - serv_code resp_code
      - serv_msg  resp_msg
  - name: set_player_id
    desc: server message to client to set player id/color
    msgs:
      - player_id pid
  - name: player_move
    desc: client message to server to make a player move
    msgs:
      - tile_id from
      - tile_id to
      - u16     armies
  - name: set_tile
    desc: server message to client to set state of a tile
    msgs:
      - tile_id   tid
      - terrain   ttype # 0 = hidden, 1 = blank, 2 = mountains, 3 = fort, 4 = home base
      - player_id owner # 0 = no owner, 1 = player 1, 2 = player, etc.
      - u16       armies
```

## How code is generated

Output program code is generated in the following manner:

1. `nmspec` file is read - the source YAML file is read
2. validity check - the YAML is checked to make sure it conforms to the `nmspec`
   subset; useful errors and warnings in formatting may be added if mistakes are
   found
3. If all is well, then the parsed YAML is converted into a data structure that
   is designed to be easy for code generators to interpret
4. The data structure is passed on to one code generator per requested output
   language
5. The resulting output code in all requested languages is gathered together and
   returned to the user

## Preliminary research, and comparison to other methods

`nmspec` is basically [rpc][rpc], except it also bundles code generators, and
not just the rpc message/protocol specifications.

I started with researching how other people had designed network protocol
description languages/tools in the past, beginning with [Prolac][prolac]. This
lead me to other network messaging tools, binary serialization in general,
finally [Google's protocol buffers][protobuffs]. Protocol buffers were probably
the closest thing to what I wanted, and took care of binary
serialization/deserialization, but weren't packaged with the networking layer,
which introduces additional considerations such as byte ordering, efficient
packet construction, TCP stack options, and communication retries and graceful
failover. While protocol buffers are a good design, and I think do a good job of
solving binary serialization as its own problem (becoming reusable for file I/O
as well as networks), I really wanted something that packaged serialization,
cross-language support, and TCP communication all in one package from a single
config file, so that a programmer needs only to write a single artifact (a
`.nmspec` file), and get the code for their target programming language(s)
generated automatically.

  [rpc]: https://en.wikipedia.org/wiki/Remote_procedure_call
  [ruby-lang]: https://www.ruby-lang.org/
  [gdscript]: https://docs.godotengine.org/en/stable/getting_started/scripting/gdscript/gdscript_basics.html
  [generals.io]: https://generals.io/
  [prolac]: https://pdos.csail.mit.edu/archive/prolac/prolac-the.pdf
  [protobuffs]: https://developers.google.com/protocol-buffers
