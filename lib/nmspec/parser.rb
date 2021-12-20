require 'yaml'

module Nmspec
  module Parser
    class << self
      BASE_TYPES = %w(
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
          }

          parsed[:types] = []
          ((spec_hash['types'] || []) + BASE_TYPES).each do |type|
            parsed[:types] << {
              name: type,
              kind: _kind_of(type),
            }
          end

          parsed[:protos] = []
          (spec_hash['protos'] || []).each do |proto|
            parsed[:protos] << {
              name: proto['name'],
              desc: proto['desc'],
              msgs: proto['msgs'].map do |msg|
                mode, type, identifier = msg.split
                {
                  mode: case mode
                        when 'r' then :read
                        when 'w' then :write
                        else
                          raise "Unknown msg mode: `#{mode}`"
                        end,
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
