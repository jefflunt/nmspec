
`nmspec` (network message specification) is a subset of YAML used to specify
the format of communication protocols between two sides of a network
connection.

I started working on this gem because of a specific challenge I was facing. I've
been working on an online game with a server backend (written in Ruby) and a
game client (created with the game engine, Godot, and its embedded scripting
language, GDScript). The challenge I kept running into was that anytime I change
something in the network code I had to:

1. Change it on the server side in one programming language
2. Change it on the client side in a different programming language
3. Debug across the network connection to figure out where bugs were

My approach to making this constantly-shifting communication easier to develop
and debug was to come up with a language-agnostic representation of the network
protocols within the game, specifically in some kind of easily editable
configuration language, and then generate both the Ruby and GDScript code from
that central source. I figured that if I could do that without too much work,
then I could also squash the client/server syncing bugs in one place (in the
protocol specification language, and related output code generators). Then if I
wanted to add a new message / protocol to either the client or server side I
could build it once - in the specification language - and have a program spit
out working code for both the client and server.

Of course that's not all there is to successful network communication, but the
bulk of bugs I've been running into were at this low-level networking layer
where the fine details of the client/server code were slipping out of sync
constantly, and little typos could lead to big debugging time sinks.

# Output language support

As a starting point this gem will support network messengers in these two
languages:

* [Ruby 3.0.x][ruby-lang]
* [GDScript 3.4][gdscript]

Additional languages can be added if there is interest. I'm mainly building this
for my own purposes, so if I'm the only person who ever uses it, that's fine
too. :)

I think it would be fun to eventually connect this gem to the internet,
allowing [a static website](http://nmspec.com/) to generate client/server code
from a specification in a web form, similar to how you can paste JSON into
[jsonlint.com](https://jsonlint.com/) and have it validate it for you without
you needing to install a local linting tool. We'll see - I might need a break
from network code some day soon, and if so, maybe I'll set that up.

# Sample usage

```ruby
# add 'nmspec' to your Gemfile

$ irb

 > require 'nmspec'
=> true
 > pp  Nmspec::V1.gen({
         'spec' => IO.read('generals.io.nmspec'),
         'langs' => ['ruby']
       })
=> {
     "valid"=>true,
     "errors"=>[],
     "warnings"=>[],
     "code"=> {
       "ruby"=> "< a string of generated Ruby code that you can save to a file>"
     }
   }
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

`demo/minimal.nmspec` shows the absolute minimum amount of information needed
to get a basic messenger working.

```yaml
version: 1

msgr:
  name: basic
  desc: this messenger only supports the built-in types, and has no custom protocols
```

`demo/base_types.nmspec` shows an example of a one-protocol messenger that is
used to ensure that all base types can be read and written correctly.

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

`demo/generals.io.nmspec` contains a theoretical implementation of a messenger
for the game, [generals.io][generals.io]:

```yaml
version: 1

msgr:
  name: generals io
  desc: a sample generals.io nmspec

types:
  - str player_name
  - i8  player_id
  - u16 tile_id
  - u8  terrain
  - u8  server_code
  - str server_msg

protos:
  - name: set_player_name
    desc: sets the player name for a given player
    msgs:
      - w player_name player_name
  - name: resp_player_name
    desc: server message to accept or reject the player name
    msgs:
      - w server_code resp_code
      - w server_msg  resp_msg
  - name: set_player_id
    desc: server message to client to set id/color
    msgs:
      - w player_id pid
  - name: player_move
    desc: player request to make a move
    msgs:
      - w tile_id from
      - w tile_id to
      - w i16     armies
  - name: set_tile
    desc: server updating client tiles
    msgs:
      - w tile_id   tid
      - w terrain   ttype # 0 = hidden, 1 = blank, 2 = mountains, 3 = fort, 4 = home base
      - w player_id owner # -1 = not owned
      - w i16       armies
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

  [ruby-lang]: https://www.ruby-lang.org/
  [gdscript]: https://docs.godotengine.org/en/stable/getting_started/scripting/gdscript/gdscript_basics.html
  [generals.io]: https://generals.io/
