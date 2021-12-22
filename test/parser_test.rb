require 'minitest/autorun'

class TestParser < Minitest::Test
  def setup
    @minimal_spec = YAML.load(IO.read('demo/minimal.nmspec'))
    @base_types_spec = YAML.load(IO.read('demo/base_types.nmspec'))
    @generals_io_spec = YAML.load(IO.read('demo/generals.io.nmspec'))
  end

  def test_parse_minimal
    assert_equal(
      {
        version: 1,
        msgr: {
          name: 'minimal',
          desc: 'this messenger only supports the built-in types, and has no custom protocols',
        },
        types: [
          {
            name: 'i8',
            base_type: nil,
            kind: 'numeric',
          },
          {
            name: "u8",
            base_type: nil,
            kind: 'numeric',
          },
          {
            name: "i8_list",
            base_type: nil,
            kind: 'numeric_list',
          },
          {
            name: "u8_list",
            base_type: nil,
            kind: 'numeric_list',
          },
          {
            name: "i16",
            base_type: nil,
            kind: 'numeric',
          },
          {
            name: "u16",
            base_type: nil,
            kind: 'numeric',
          },
          {
            name: "i16_list",
            base_type: nil,
            kind: 'numeric_list',
          },
          {
            name: "u16_list",
            base_type: nil,
            kind: 'numeric_list',
          },
          {
            name: "i32",
            base_type: nil,
            kind: 'numeric',
          },
          {
            name: "u32",
            base_type: nil,
            kind: 'numeric',
          },
          {
            name: "i32_list",
            base_type: nil,
            kind: 'numeric_list',
          },
          {
            name: "u32_list",
            base_type: nil,
            kind: 'numeric_list',
          },
          {
            name: "i64",
            base_type: nil,
            kind: 'numeric',
          },
          {
            name: "u64",
            base_type: nil,
            kind: 'numeric',
          },
          {
            name: "i64_list",
            base_type: nil,
            kind: 'numeric_list',
          },
          {
            name: "u64_list",
            base_type: nil,
            kind: 'numeric_list',
          },
          {
            name: "float",
            base_type: nil,
            kind: 'numeric',
          },
          {
            name: "float_list",
            base_type: nil,
            kind: 'numeric_list',
          },
          {
            name: "double",
            base_type: nil,
            kind: 'numeric',
          },
          {
            name: "double_list",
            base_type: nil,
            kind: 'numeric_list',
          },
          {
            name: "str",
            base_type: nil,
            kind: 'str',
          },
          {
            name: "str_list",
            base_type: nil,
            kind: 'str_list',
          },
        ],
        protos: [],
      },
      Nmspec::Parser.parse(@minimal_spec),
    )
  end

  def test_parse_base_types
    assert_equal(
      {
        version: 1,
        msgr: {
          name: 'base types',
          desc: 'this messenger supports the built-in types, and is mainly used for testing code generators'
        },
        types: [
          {
            name: 'i8',
            base_type: nil,
            kind: 'numeric',
          },
          {
            name: "u8",
            base_type: nil,
            kind: 'numeric',
          },
          {
            name: "i8_list",
            base_type: nil,
            kind: 'numeric_list',
          },
          {
            name: "u8_list",
            base_type: nil,
            kind: 'numeric_list',
          },
          {
            name: "i16",
            base_type: nil,
            kind: 'numeric',
          },
          {
            name: "u16",
            base_type: nil,
            kind: 'numeric',
          },
          {
            name: "i16_list",
            base_type: nil,
            kind: 'numeric_list',
          },
          {
            name: "u16_list",
            base_type: nil,
            kind: 'numeric_list',
          },
          {
            name: "i32",
            base_type: nil,
            kind: 'numeric',
          },
          {
            name: "u32",
            base_type: nil,
            kind: 'numeric',
          },
          {
            name: "i32_list",
            base_type: nil,
            kind: 'numeric_list',
          },
          {
            name: "u32_list",
            base_type: nil,
            kind: 'numeric_list',
          },
          {
            name: "i64",
            base_type: nil,
            kind: 'numeric',
          },
          {
            name: "u64",
            base_type: nil,
            kind: 'numeric',
          },
          {
            name: "i64_list",
            base_type: nil,
            kind: 'numeric_list',
          },
          {
            name: "u64_list",
            base_type: nil,
            kind: 'numeric_list',
          },
          {
            name: "float",
            base_type: nil,
            kind: 'numeric',
          },
          {
            name: "float_list",
            base_type: nil,
            kind: 'numeric_list',
          },
          {
            name: "double",
            base_type: nil,
            kind: 'numeric',
          },
          {
            name: "double_list",
            base_type: nil,
            kind: 'numeric_list',
          },
          {
            name: "str",
            base_type: nil,
            kind: 'str',
          },
          {
            name: "str_list",
            base_type: nil,
            kind: 'str_list',
          },
        ],
        protos: [
          {
            name: 'all_base_types',
            desc: 'write all base types',
            msgs: [
              {
                mode: :write,
                type: 'i8',
                identifier: 'i8',
              },
              {
                mode: :write,
                type: 'u8',
                identifier: 'u8',
              },
              {
                mode: :write,
                type: 'i8_list',
                identifier: 'i8_list',
              },
              {
                mode: :write,
                type: 'u8_list',
                identifier: 'u8_list',
              },
              {
                mode: :write,
                type: 'i16',
                identifier: 'i16',
              },
              {
                mode: :write,
                type: 'u16',
                identifier: 'u16',
              },
              {
                mode: :write,
                type: 'i16_list',
                identifier: 'i16_list',
              },
              {
                mode: :write,
                type: 'u16_list',
                identifier: 'u16_list',
              },
              {
                mode: :write,
                type: 'i32',
                identifier: 'i32',
              },
              {
                mode: :write,
                type: 'u32',
                identifier: 'u32',
              },
              {
                mode: :write,
                type: 'i32_list',
                identifier: 'i32_list',
              },
              {
                mode: :write,
                type: 'u32_list',
                identifier: 'u32_list',
              },
              {
                mode: :write,
                type: 'i64',
                identifier: 'i64',
              },
              {
                mode: :write,
                type: 'u64',
                identifier: 'u64',
              },
              {
                mode: :write,
                type: 'i64_list',
                identifier: 'i64_list',
              },
              {
                mode: :write,
                type: 'u64_list',
                identifier: 'u64_list',
              },
              {
                mode: :write,
                type: 'float',
                identifier: 'float',
              },
              {
                mode: :write,
                type: 'float_list',
                identifier: 'float_list',
              },
              {
                mode: :write,
                type: 'double',
                identifier: 'double',
              },
              {
                mode: :write,
                type: 'double_list',
                identifier: 'double_list',
              },
              {
                mode: :write,
                type: 'str',
                identifier: 'str',
              },
              {
                mode: :write,
                type: 'str_list',
                identifier: 'str_list',
              },
            ],
          },
        ],
      },
      Nmspec::Parser.parse(@base_types_spec),
    )
  end

  def test_parse_generals_io
    assert_equal(
      {
        version: 1,
        msgr: {
          name: 'generals io',
          desc: 'a sample generals.io nmspec'
        },
        types: [
          {
            name: 'i8',
            base_type: nil,
            kind: 'numeric',
          },
          {
            name: "u8",
            base_type: nil,
            kind: 'numeric',
          },
          {
            name: "i8_list",
            base_type: nil,
            kind: 'numeric_list',
          },
          {
            name: "u8_list",
            base_type: nil,
            kind: 'numeric_list',
          },
          {
            name: "i16",
            base_type: nil,
            kind: 'numeric',
          },
          {
            name: "u16",
            base_type: nil,
            kind: 'numeric',
          },
          {
            name: "i16_list",
            base_type: nil,
            kind: 'numeric_list',
          },
          {
            name: "u16_list",
            base_type: nil,
            kind: 'numeric_list',
          },
          {
            name: "i32",
            base_type: nil,
            kind: 'numeric',
          },
          {
            name: "u32",
            base_type: nil,
            kind: 'numeric',
          },
          {
            name: "i32_list",
            base_type: nil,
            kind: 'numeric_list',
          },
          {
            name: "u32_list",
            base_type: nil,
            kind: 'numeric_list',
          },
          {
            name: "i64",
            base_type: nil,
            kind: 'numeric',
          },
          {
            name: "u64",
            base_type: nil,
            kind: 'numeric',
          },
          {
            name: "i64_list",
            base_type: nil,
            kind: 'numeric_list',
          },
          {
            name: "u64_list",
            base_type: nil,
            kind: 'numeric_list',
          },
          {
            name: "float",
            base_type: nil,
            kind: 'numeric',
          },
          {
            name: "float_list",
            base_type: nil,
            kind: 'numeric_list',
          },
          {
            name: "double",
            base_type: nil,
            kind: 'numeric',
          },
          {
            name: "double_list",
            base_type: nil,
            kind: 'numeric_list',
          },
          {
            name: "str",
            base_type: nil,
            kind: 'str',
          },
          {
            name: "str_list",
            base_type: nil,
            kind: 'str_list',
          },
          {
            name: 'player_name',
            base_type: 'str',
            kind: 'str',
          },
          {
            name: 'player_id',
            base_type: 'i8',
            kind: 'numeric',
          },
          {
            name: 'tile_id',
            base_type: 'u16',
            kind: 'numeric',
          },
          {
            name: 'terrain',
            base_type: 'u8',
            kind: 'numeric',
          },
          {
            name: 'server_code',
            base_type: 'u8',
            kind: 'numeric',
          },
          {
            name: 'server_msg',
            base_type: 'str',
            kind: 'str',
          },
        ],
        protos: [
          {
            name: 'set_player_name',
            desc: 'sets the player name for a given player',
            msgs: [
              {
                mode: :write,
                type: 'player_name',
                identifier: 'player_name',
              },
            ],
          },
          {
            name: 'resp_player_name',
            desc: 'server message to accept or reject the player name',
            msgs: [
              {
                mode: :write,
                type: 'server_code',
                identifier: 'resp_code',
              },
              {
                mode: :write,
                type: 'server_msg',
                identifier: 'resp_msg',
              },
            ],
          },
          {
            name: 'set_player_id',
            desc: 'server message to client to set id/color',
            msgs: [
              {
                mode: :write,
                type: 'player_id',
                identifier: 'pid',
              },
            ],
          },
          {
            name: 'player_move',
            desc: 'player request to make a move',
            msgs: [
              {
                mode: :write,
                type: 'tile_id',
                identifier: 'from',
              },
              {
                mode: :write,
                type: 'tile_id',
                identifier: 'to',
              },
              {
                mode: :write,
                type: 'i16',
                identifier: 'armies',
              },
            ],
          },
          {
            name: 'set_tile',
            desc: 'server updating client tiles',
            msgs: [
              {
                mode: :write,
                type: 'tile_id',
                identifier: 'tid',
              },
              {
                mode: :write,
                type: 'terrain',
                identifier: 'ttype',
              },
              {
                mode: :write,
                type: 'player_id',
                identifier: 'owner',
              },
              {
                mode: :write,
                type: 'i16',
                identifier: 'armies',
              },
            ],
          },
        ],
      },
      Nmspec::Parser.parse(@generals_io_spec),
    )
  end
end
