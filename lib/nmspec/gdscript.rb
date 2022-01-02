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

        code << 'extends Reference'
        code << ''
        code << "class_name #{_class_name_from_msgr_name(spec.dig(:msgr, :name))}"
        code << ''

        if (spec[:protos]&.length || 0) > 0
          code << _opcode_mappings(spec[:protos])
          code << ''
        end

        code << '###########################################'
        code << '# setup'
        code << 'var socket = null'
        code << ''
        code << _init
        code << ''
        code << _connected
        code << ''
        code << _errored
        code << ''
        code << _has_bytes
        code << ''
        code << _ready_bytes
        code << ''
        code << _close
        code << ''

        code << _str_types
        code << ''
        code << _list_types

        subtypes = spec[:types].select{|t| !t[:base_type].nil? }
        code << _protos_methods(spec[:protos], subtypes)

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

      def _opcode_mappings(protos)
        code = []

        code << 'const PROTO_TO_OP = {'
        code += protos.map.with_index{|p, i| "\t'#{p[:name]}': #{i}," }
        code << '}'

        code << ''

        code << 'const OP_TO_PROTO = {'
        code += protos.map.with_index{|p, i| "\t#{i}: '#{p[:name]}'," }
        code << '}'

        code
      end

      def _init
        code = []

        code << '# WARN: Messengers in GDScript assume big_endian byte order'
        code << '# WARN: this means sockets that use little-endian will tend to lock up'
        code << 'func _init(_socket):'
        code << "\tsocket = _socket"
        code << "\tsocket.set_big_endian(true)"
        code << "\tsocket.set_no_delay(false)"

        code
      end

      def _close
        code = []

        code << '# calls .disconnect_from_host() on the underlying socket'
        code << 'func _close():'
        code << "\tsocket.disconnect_from_host()"
      end

      def _connected
        code = []

        code << '# returns true if the messenger is connected, false otherwise'
        code << 'func _connected():'
        code << "\treturn socket != null && socket.get_status() == StreamPeerTCP.STATUS_CONNECTED"

        code
      end

      def _errored
        code = []

        code << '# returns true if the messenger has errored, false otherwise'
        code << 'func _errored():'
        code << "\treturn socket != null && socket.get_status() == StreamPeerTCP.STATUS_ERROR"

        code
      end

      def _has_bytes
        code = []

        code << '# returns true if there are bytes to be read, false otherwise'
        code << 'func _has_bytes():'
        code << "\treturn _ready_bytes() > 0"

        code
      end

      def _ready_bytes
        code = []

        code << '# returns the number of bytes ready for reading'
        code << 'func _ready_bytes():'
        code << "\treturn socket.get_available_bytes()"

        code
      end

      def _str_types
        code = []

        code << '###########################################'
        code << '# string types'
        code << "func r_str():"
        code << "\treturn socket.get_data(socket.get_u32())[1].get_string_from_ascii()"
        code << ""
        code << "func w_str(string):"
        code << "\tsocket.put_u32(string.length())"
        code << "\tsocket.put_data(string.to_ascii())"

        code
      end

      def _list_types
        code = []

        code << '###########################################'
        code << '# list types'

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

        code << "func r_str_list():"
        code << "\tvar n = socket.get_u32()"
        code << "\tvar strings = []"
        code << ""
        code << "\tfor _i in range(n):"
        code << "\t\tstrings.append(socket.get_data(socket.get_u32())[1].get_string_from_ascii())"
        code << ""
        code << "\treturn strings"
        code << ""
        code << "func w_str_list(strings):"
        code << "\tvar n = strings.size()"
        code << "\tsocket.put_u32(strings.size())"
        code << ""
        code << "\tfor i in range(n):"
        code << "\t\tsocket.put_u32(strings[i].length())"
        code << "\t\tsocket.w_str(strings[i])"

        code
      end

      def _type_list_reader_writer_methods(type, num_bits)
        code = []

        put_type = type.start_with?('i') ? type[1..] : type
        code << "func r_#{type}():"
        code << "\tvar n = socket.get_u32()"
        code << "\tvar arr = []"
        code << ""
        code << "\tfor _i in range(n):"
        code << "\t\tarr.append(socket.get_#{num_bits}())"
        code << ""
        code << "\treturn arr"
        code << ""
        code << "func w_#{type}(#{type}):"
        code << "\tvar n = #{type}.size()"
        code << "\tsocket.put_u32(n)"
        code << ""
        code << "\tfor i in range(n):"
        code << "\t\tsocket.put_#{put_type.split('_list').first}(#{type}[i])"
        code << ""
        code
      end

      ##
      # builds all msg methods
      def _protos_methods(protos=[], subtypes=[])
        code = []

        return code unless protos && protos&.length > 0

        code << ''
        code << '###########################################'
        code << '# messages'

        protos.each_with_index do |proto, proto_code|
          # This figures out which identifiers mentioned in the msg
          # definition must be passed in vs. declared within the method

          code << ''
          send_local_vars = []
          recv_local_vars = []
          send_passed_params, recv_passed_params = proto[:msgs]
            .inject([[], []]) do |all_params, msg|
              msg[:type] = _replace_reserved_word(msg[:type])
              msg[:identifier] = _replace_reserved_word(msg[:identifier])
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

              [send_params.uniq, recv_params.uniq]
            end

          ##
          # send
          code << _proto_method('send', proto_code, proto, send_local_vars, send_passed_params, subtypes)
          code << _proto_method('recv', proto_code, proto, recv_local_vars, recv_passed_params, subtypes)
        end

        if protos.length > 0
          code << ''
          code << "# This method is used when you're receiving protocol messages"
          code << "# in an unknown order, and dispatching automatically."
          code << "func recv_any():"
          code << "\tmatch socket.get_u8():"

          protos.each_with_index do |proto, proto_code|
            code << "\t\t#{proto_code}:"
            code << "\t\t\treturn [#{proto_code}, recv_#{proto[:name]}()]"
          end
        end

        code
      end

      def _replace_reserved_word(word)
        case word
        when 'float' then 'flt'
        when 'str'   then 'string'
        when 'floor' then 'flr'
        else
          word
        end
      end

      ##
      # Builds a single protocol method
      def _proto_method(kind, proto_code, proto, local_vars, passed_params, subtypes)
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
        code << "\tsocket.put_u8(#{proto_code})" if kind.eql?('send')
        msgs.each do |msg|
          msg = kind.eql?('send') ? msg : _flip_mode(msg)
          code << "\t#{_line_from_msg(msg, subtypes)}"
        end

        code << "\treturn [#{local_vars.map{|v| v.last }.uniq.join(', ')}]"

        code
      end

      def _flip_mode(msg)
        opposite_mode = msg[:mode] == :read ? :write : :read
        { mode: opposite_mode, type: msg[:type], identifier: msg[:identifier] }
      end

      def _line_from_msg(msg, subtypes)
        subtype = subtypes.detect{|st| st[:name] == msg[:type] }&.dig(:base_type)
        mode = msg[:mode]
        type = _replace_reserved_word(subtype || msg[:type])
        identifier = msg[:identifier]

        type = type.start_with?('i') ? type[1..] : type

        case mode
        when :read
          case
          when type.end_with?('_list')
            "var #{identifier} = r_#{type}()"
          when type.eql?('string')
            "var #{identifier} = r_str()"
          else
            "var #{identifier} = socket.get_#{type}()"
          end
        when :write
          case
          when type.end_with?('_list')
            "w_#{type}(#{identifier})"
          when type.eql?('string')
            "w_str(#{identifier})"
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
