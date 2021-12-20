require 'minitest/autorun'

class TestParser < Minitest::Test
  def setup
    @minimal_spec = YAML.load(IO.read('demo/minimal.nmspec'))
    @base_types_spec = YAML.load(IO.read('demo/base_types.nmspec'))
  end

  def test_parse_minimal
    assert_equal(
      {
        version: 1,
        msgr: {
          name: 'basic',
          desc: 'this messenger only supports the built-in types, and has no custom protocols',
        },
        types: [
          {
            name: 'i8',
            kind: 'numeric',
          },
          {
            name: "u8",
            kind: 'numeric',
          },
          {
            name: "i8_list",
            kind: 'numeric_list',
          },
          {
            name: "u8_list",
            kind: 'numeric_list',
          },
          {
            name: "i16",
            kind: 'numeric',
          },
          {
            name: "u16",
            kind: 'numeric',
          },
          {
            name: "i16_list",
            kind: 'numeric_list',
          },
          {
            name: "u16_list",
            kind: 'numeric_list',
          },
          {
            name: "i32",
            kind: 'numeric',
          },
          {
            name: "u32",
            kind: 'numeric',
          },
          {
            name: "i32_list",
            kind: 'numeric_list',
          },
          {
            name: "u32_list",
            kind: 'numeric_list',
          },
          {
            name: "i64",
            kind: 'numeric',
          },
          {
            name: "u64",
            kind: 'numeric',
          },
          {
            name: "i64_list",
            kind: 'numeric_list',
          },
          {
            name: "u64_list",
            kind: 'numeric_list',
          },
          {
            name: "float",
            kind: 'numeric',
          },
          {
            name: "float_list",
            kind: 'numeric_list',
          },
          {
            name: "double",
            kind: 'numeric',
          },
          {
            name: "double_list",
            kind: 'numeric_list',
          },
          {
            name: "str",
            kind: 'str',
          },
          {
            name: "str_list",
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
          desc: 'this messenger includes a single protocol that is used to test reading/writing of all base types'
        },
        types: [
          {
            name: 'i8',
            kind: 'numeric',
          },
          {
            name: "u8",
            kind: 'numeric',
          },
          {
            name: "i8_list",
            kind: 'numeric_list',
          },
          {
            name: "u8_list",
            kind: 'numeric_list',
          },
          {
            name: "i16",
            kind: 'numeric',
          },
          {
            name: "u16",
            kind: 'numeric',
          },
          {
            name: "i16_list",
            kind: 'numeric_list',
          },
          {
            name: "u16_list",
            kind: 'numeric_list',
          },
          {
            name: "i32",
            kind: 'numeric',
          },
          {
            name: "u32",
            kind: 'numeric',
          },
          {
            name: "i32_list",
            kind: 'numeric_list',
          },
          {
            name: "u32_list",
            kind: 'numeric_list',
          },
          {
            name: "i64",
            kind: 'numeric',
          },
          {
            name: "u64",
            kind: 'numeric',
          },
          {
            name: "i64_list",
            kind: 'numeric_list',
          },
          {
            name: "u64_list",
            kind: 'numeric_list',
          },
          {
            name: "float",
            kind: 'numeric',
          },
          {
            name: "float_list",
            kind: 'numeric_list',
          },
          {
            name: "double",
            kind: 'numeric',
          },
          {
            name: "double_list",
            kind: 'numeric_list',
          },
          {
            name: "str",
            kind: 'str',
          },
          {
            name: "str_list",
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
end
