require 'yaml'

module Nmspec
  module Parser
    class << self
      BASE_TYPES = %w(
                      bool
                      i8 u8   i8_list  u8_list
                      i16 u16 i16_list u16_list
                      i32 u32 i32_list u32_list
                      i64 u64 i64_list u64_list
                      float   float_list
                      double  double_list
                      str     str_list
                   )

      def parse(spec_hash)
        spec_hash

        {}.tap do |parsed|
          parsed[:version] = spec_hash['version']
          parsed[:msgr] = {
            name: spec_hash.dig('msgr', 'name'),
            desc: spec_hash.dig('msgr', 'desc'),
            nodelay: spec_hash.dig('msgr', 'nodelay') || false,
            bigendian: spec_hash.dig('msgr', 'bigendian').nil? ? true : spec_hash.dig('msgr', 'bigendian')
          }

          parsed[:types] = []
          BASE_TYPES.each do |type|
            parsed[:types] << {
              name: type,
              base_type: nil,
              kind: _kind_of(type),
            }
          end

          (spec_hash['types'] || []).each do |type_spec|
            base_type, name = type_spec.split
            parsed[:types] << {
              name: name,
              base_type: base_type,
              kind: _kind_of(base_type),
            }
          end

          parsed[:protos] = []
          (spec_hash['protos'] || []).each do |proto|
            msgs = (proto['msgs'] || [])
            parsed[:protos] << {
              name: proto['name'],
              desc: proto['desc'],
              msgs: msgs.map do |msg|
                type, identifier = msg.split
                {
                  mode: :write,
                  type: type,
                  identifier: identifier,
                }
              end
            }
          end
        end
      end

      def _kind_of(type)
        case type
        when 'bool'
          'bool'
        when /\A(float|double|[ui]\d{1,2})\Z/
          'numeric'
        when /\A(float|double|[ui]\d{1,2})_list\Z/
          'numeric_list'
        when 'str'
          'str'
        when 'str_list'
          'str_list'
        else
          raise "Unknown kind of type: `#{type}`"
        end
      end
    end
  end
end
