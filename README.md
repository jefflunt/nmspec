`nmspec` (short for 'network message specification') is a subset of YAML used to
specify the format of messages between two sides of a network connection.

This gem will support network messengers in these two languages:

* [Ruby 3.0.x][1]
* [GDScript 3.4][2]

Additional languages can be added if there is interest. If so, then I will move
the Ruby and GDScript code generators to their own gems, and encourage other
language contributors to build their own gems to support their output languages.

TODO:

* Upload demo video
* Include `sample.nmspec` file
* Add contribution file

# Sample usage

```ruby
pp  Nmspec::V1.gen(
      {
        'spec' => IO.read('generals.io.nmspec'),
        'langs' => ['ruby']
      }
    )
```

# `nmspec` format

`nmspec` is a subset of YAML. So, first and foremost, if your `.nmspec` file is
not valid YAML, then it's definitely not valid `nmspec`.

## Required keys:

* `version` - which currently must be set to `1`
* `msgr` - the top-level key for naming and describing the messenger
* `msgs` - a list of messages specified by the file

## Optional keys:

* `types` - if your `.nmspec` file creates custom sub-types, then this is where
  you declare them

**see**: `generals.io.nmspec` for a sample file

  [1]: https://www.ruby-lang.org/
  [2]: https://docs.godotengine.org/en/stable/getting_started/scripting/gdscript/gdscript_basics.html
