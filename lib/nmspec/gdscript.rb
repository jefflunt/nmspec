require 'set'

# Nmspec code generator for ruby
module Nmspec
  module GDScript
    class << self
      def gen(spec)
        code = []
        code << '##'
        code << '# NOTE: this code is auto-generated from an nmspec file'

        if spec.dig(:msgr, :desc)
          code << '#'
          code << "# #{spec.dig(:msgr, :desc)}"
        end

        code << ''
        code << 'extends Node'
        code << ''
        code << "class_name #{_class_name_from_msgr_name(spec.dig(:msgr, :name))}"
        code << ''

        code << '###########################################'
        code << '# setup'
        code << '###########################################'
        code << ''
        code << 'var socket = StreamPeerTCP.new()'
        code << ''
        code << _socket_setter

        code << ''
        code << _list_types

        code << _protos_methods(spec[:protos])

        code.join("\n")
      rescue => e
        "Code generation failed due to unknown error: check spec validity\n  cause: #{e.inspect}"
        puts e.backtrace.join("\n  ")
      end

      def _class_name_from_msgr_name(name)
        name
          .downcase
          .gsub(/[\._\-]/, ' ')
          .split(' ')
          .map{|part| part.capitalize}
          .join + 'Msgr'
      end

      def _socket_setter
        code = []

        code << 'func set_socket(s):'
        code << '  socket = s'

        code
      end

      def _list_types
        code = []

        code << '###########################################'
        code << '# list types'
        code << '###########################################'
        code << ''

        ::Nmspec::V1::BASE_TYPES
          .each do |type|
            # See https://www.rubydoc.info/stdlib/core/1.9.3/Array:pack
            num_bits =  case type
                        when 'float_list'           then 32
                        when 'double_list'          then 64
                        when 'i8_list','u8_list'    then 8
                        when 'i16_list','u16_list'  then 16
                        when 'i32_list','u32_list'  then 32
                        when 'i64_list','u64_list'  then 64
                        else
                          next
                        end

            code << _type_list_reader_writer_methods(type, num_bits)
          end

        code << 'func r_str_list():'
        code << '  var n = socket.get_u16()'
        code << '  var strings = []'
        code << ''
        code << '  for i in range(n):'
        code << '    strings.append(socket.get_string(socket.get_u16()))'
        code << ''
        code << '  return strings'
        code << ''
        code << 'func w_str_list(strings):'
        code << '  var n = strings.size()'
        code << '  socket.put_u16(strings.size())'
        code << ''
        code << '  for i in range(n):'
        code << '    socket.put_u16(strings[i].length())'
        code << '    socket.put_str(strings[i])'

        code
      end

      def _type_list_reader_writer_methods(type, num_bits)
        code = []

        code << "func r_#{type}():"
        code << '  var n = socket.get_u16()'
        code << '  var arr = []'
        code << ''
        code << '  for i in range(n):'
        code << "    arr.append(socket.get_#{num_bits}()"
        code << ''
        code << '  return arr'
        code << ''
        code << "func w_#{type}(#{type}):"
        code << "  var n = #{type}.size()"
        code << '  socket.put_u16(n)'
        code << ''
        code << '  for i in range(n):'
        code << "    socket.put_#{type.split('_list').first}(#{type}[i])"
        code << ''

        code
      end

      ##
      # builds all msg methods
      def _protos_methods(protos=[])
        code = []

        return code unless protos && protos&.length > 0

        code << ''
        code << '###########################################'
        code << '# messages'
        code << '###########################################'

        protos.each_with_index do |proto, proto_code|
          # This figures out which identifiers mentioned in the msg
          # definition must be passed in vs. declared within the method

          next unless proto.has_key?(:msgs) && !proto[:msgs].empty?

          code << ''
          send_local_vars = []
          recv_local_vars = []
          send_passed_params, recv_passed_params = proto[:msgs]
            .inject([Set.new, Set.new]) do |all_params, msg|
              send_params, recv_params = all_params

              mode = msg[:mode]
              type = msg[:type]
              identifier = msg[:identifier]

              case mode
              when :read
                send_local_vars << [type, identifier]
                recv_params << identifier unless recv_local_vars.map{|v| v.last}.include?(identifier)
              when :write
                recv_local_vars << [type, identifier]
                send_params << identifier unless send_local_vars.map{|v| v.last}.include?(identifier)
              else
                raise "Unsupported mode: `#{mode}`"
              end

              [send_params, recv_params]
            end

          ##
          # send
          code << _proto_method('send', proto_code, proto, send_local_vars, send_passed_params)
          code << ''
          code << _proto_method('recv', proto_code, proto, recv_local_vars, recv_passed_params)
        end

        code
      end

      ##
      # Builds a single protocol method
      def _proto_method(kind, proto_code, proto, local_vars, passed_params)
        code = []

        code << "# #{proto[:desc]}" if proto[:desc]
        unless local_vars.empty?
          code << '#'
          code << '# returns:  (type | local var name)'
          code << '# ['
          local_vars.uniq.each{|v| code << "  #    #{"#{v.first}".ljust(12)} | #{v.last}" }
          code << '# ]'
        end

        code << "func #{kind}_#{proto[:name]}#{passed_params.length > 0 ? "(#{(passed_params.to_a).join(', ')})" : '()'}:"

        msgs = proto[:msgs]
        code << "  socket.put_8(#{proto_code})" if kind.eql?('send')
        msgs.each do |msg|
          msg = kind.eql?('send') ? msg : _flip_mode(msg)
          code << "  #{_line_from_msg(msg)}"
        end
        code << "\n  return [#{local_vars.map{|v| v.last }.uniq.join(', ')}]" unless local_vars.empty?

        code
      end

      def _flip_mode(msg)
        opposite_mode = msg[:mode] == :read ? :write : :read
        { mode: opposite_mode, type: msg[:type], identifier: msg[:identifier] }
      end

      def _line_from_msg(msg)
        mode = msg[:mode]
        type = msg[:type]
        identifier = msg[:identifier]

        case mode
        when :read
          case
          when type.end_with?('_list')
            "var #{identifier} = r_#{type}()"
          else
            "var #{identifier} = socket.get_#{type}()"
          end
        when :write
          case
          when type.end_with?('_list')
            "w_#{type}(#{identifier})"
          else
            "socket.put_#{type}(#{identifier})"
          end
        else
          raise "Unsupported message msg mode: `#{mode}`"
        end
      end
    end
  end
end
