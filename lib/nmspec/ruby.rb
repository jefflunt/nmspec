require 'set'

# Nmspec code generator for ruby
module Nmspec
  module Ruby
    class << self
      def gen(spec)
        endian_marker = spec.dig(:msgr, :bigendian) ? '>' : '<'

        code = []
        code << "require 'socket'"
        code << ''
        code << '##'
        code << '# NOTE: this code is auto-generated from an nmspec file'

        if spec.dig(:msgr, :desc)
          code << '#'
          code << "# #{spec.dig(:msgr, :desc)}"
        end

        code << "class #{_class_name_from_msgr_name(spec.dig(:msgr, :name))}"

        if (spec[:protos]&.length || 0) > 0
          code << _opcode_mappings(spec[:protos])
          code << ''
        end

        code << _initialize
        code << ''
        code << _open?
        code << ''
        code << _close
        code << ''
        code << _bool_type
        code << ''
        code << _numeric_types(endian_marker)
        code << _str_types(endian_marker)
        code << _list_types(endian_marker)

        types = spec[:types]
        code << _subtype_aliases(types)
        code << _protos_methods(spec[:protos])

        code << "end"

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

        code << '  PROTO_TO_OP = {'
        code += protos.map.with_index{|p, i| "    '#{p[:name]}' => #{i}," }
        code << '  }'

        code << ''

        code << '  OP_TO_PROTO = {'
        code += protos.map.with_index{|p, i| "    #{i} => '#{p[:name]}'," }
        code << '  }'

        code
      end

      def _initialize
        code = []

        code << '  def initialize(socket, no_delay=false)'
        code << '    @socket = socket'
        code << '    @open = true'
        code << '    @socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1) if no_delay'
        code << '  end'

        code
      end

      def _open?
        code = []

        code << '  ##'
        code << '  # closes the socket inside this object'
        code << '  def open?'
        code << '    !!(@socket && @open)'
        code << '  end'

        code
      end

      def _close
        code = []

        code << '  ##'
        code << '  # closes the socket inside this object'
        code << '  def close'
        code << '    @open = false'
        code << '    @socket&.close'
        code << '  end'

        code
      end

      def _subtype_aliases(types)
        return unless types.detect{|t| !t[:base_type].nil? }
        code = []

        code << '  ###########################################'
        code << '  # subtype aliases'
        code << '  ###########################################'
        code << ''
        types.each do |type_hash|
          next unless type_hash[:base_type]
          code << "  alias_method :r_#{type_hash[:name]}, :r_#{type_hash[:base_type]}"
          code << "  alias_method :w_#{type_hash[:name]}, :w_#{type_hash[:base_type]}"
        end

        code
      end

      ##
      # inserts the boolean type readers and writers
      def _bool_type
        code = []

        code << '  ###########################################'
        code << '  # boolean type'
        code << '  ###########################################'
        code << ''
        code << "  def r_bool"
        code << "    @socket.recv(1).unpack('C')[0] == 1"
        code << '  end'
        code << ''
        code << "  def w_bool(bool)"
        code << "    @socket.send([bool ? 1 : 0].pack('C'), 0)"
        code << '  end'

        code
      end

      ##
      # inserts the boilerplate base type readers and writers
      def _numeric_types(endian_marker)
        code = []

        code << '  ###########################################'
        code << '  # numeric types'
        code << '  ###########################################'
        code << ''

        ::Nmspec::V1::BASE_TYPES
          .each do |type|
            # See https://www.rubydoc.info/stdlib/core/1.9.3/Array:pack
            num_bytes, pack_type =  case type
                                    when 'float'
                                      [4, endian_marker.eql?('>') ? 'g' : 'e']
                                    when 'double'
                                      [8, endian_marker.eql?('>') ? 'G' : 'E']
                                    when 'i8','u8'
                                      [1, type.start_with?('i') ? 'c' : 'C']
                                    when 'i16','u16'
                                      [2, type.start_with?('i') ? "s#{endian_marker}" : "S#{endian_marker}"]
                                    when 'i32','u32'
                                      [4, type.start_with?('i') ? "l#{endian_marker}" : "L#{endian_marker}"]
                                    when 'i64','u64'
                                      [8, type.start_with?('i') ? "q#{endian_marker}" : "Q#{endian_marker}"]
                                    else
                                      next
                                    end

            code << _type_reader_writer_methods(type, num_bytes, pack_type)
          end

        code
      end

      def _type_reader_writer_methods(type, num_bytes, pack_type=nil)
        code = []

        send_contents = pack_type ?  "([#{type}].pack('#{pack_type}'), 0)" : "(#{type}, 0)"
        recv_contents = pack_type ? "(#{num_bytes}).unpack('#{pack_type}')" : "(#{num_bytes})"

        code << "  def r_#{type}"
        code << "    @socket.recv#{recv_contents}.first"
        code << '  end'
        code << ''
        code << "  def w_#{type}(#{type})"
        code << "    @socket.send#{send_contents}"
        code << '  end'
        code << ''

        code
      end

      def _str_types(endian_marker)
        code = []

        code << '  ###########################################'
        code << '  # str types'
        code << '  ###########################################'
        code << ''
        code << "  def r_str"
        code << "    bytes = @socket.recv(4).unpack('L#{endian_marker}').first"
        code << "    @socket.recv(bytes)"
        code << '  end'
        code << ''
        code << "  def w_str(str)"
        code << "    @socket.send([str.length].pack('L#{endian_marker}'), 0)"
        code << "    @socket.send(str, 0)"
        code << '  end'
        code << ''
        code << "  def r_str_list"
        code << '    strings = []'
        code << ''
        code << "    @socket.recv(4).unpack('L#{endian_marker}').first.times do"
        code << "      str_length = @socket.recv(4).unpack('L#{endian_marker}').first"
        code << "      strings << @socket.recv(str_length)"
        code << '    end'
        code << ''
        code << '    strings'
        code << '  end'
        code << ''
        code << "  def w_str_list(str_list)"
        code << "    @socket.send([str_list.length].pack('L#{endian_marker}'), 0)"
        code << '    str_list.each do |str|'
        code << "      @socket.send([str.length].pack('L#{endian_marker}'), 0)"
        code << "      @socket.send(str, 0)"
        code << '    end'
        code << '  end'
        code << ''

        code
      end

      # This includes str, and anything with '*_list' in the type name
      def _list_types(endian_marker)
        code = []

        code << '  ###########################################'
        code << '  # list types'
        code << '  ###########################################'
        code << ''

        ::Nmspec::V1::BASE_TYPES
          .each do |type|
            # See https://www.rubydoc.info/stdlib/core/1.9.3/Array:pack
            num_bytes, pack_type =  case type
                                    when 'float_list'
                                      [4, endian_marker.eql?('>') ? 'g' : 'e']
                                    when 'double_list'
                                      [8, endian_marker.eql?('>') ? 'G' : 'E']
                                    when 'i8_list','u8_list'
                                      [1, type.start_with?('i') ? 'c' : 'C']
                                    when 'i16_list','u16_list'
                                      [2, type.start_with?('i') ? "s#{endian_marker}" : "S#{endian_marker}"]
                                    when 'i32_list','u32_list'
                                      [4, type.start_with?('i') ? "l#{endian_marker}" : "L#{endian_marker}"]
                                    when 'i64_list','u64_list'
                                      [8, type.start_with?('i') ? "q#{endian_marker}" : "Q#{endian_marker}"]
                                    else
                                      next
                                    end

            code << _type_list_reader_writer_methods(type, num_bytes, endian_marker, pack_type)
          end

        code
      end

      def _type_list_reader_writer_methods(type, num_bytes, endian_marker, pack_type=nil)
        code = []

        send_contents = pack_type ?  "(#{type}.pack('#{pack_type}*'), 0)" : "(#{type}, 0)"
        recv_contents = pack_type ? "(#{num_bytes} * #{type}.length).unpack('#{pack_type}*')" : "(#{num_bytes})"

        code << "  def r_#{type}"
        code << "    list_len = @socket.recv(4).unpack('L#{endian_marker}').first"
        code << "    @socket.recv(list_len * #{num_bytes}).unpack('#{pack_type}*')"
        code << '  end'
        code << ''
        code << "  def w_#{type}(#{type})"
        code << "    @socket.send([#{type}.length].pack('L#{endian_marker}'), 0)"
        code << "    @socket.send(#{type}.pack('#{pack_type}*'), 0)"
        code << '  end'
        code << ''

        code
      end

      ##
      # builds all msg methods
      def _protos_methods(protos=[])
        code = []

        return code unless protos && protos&.length > 0

        code << '  ###########################################'
        code << '  # messages'
        code << '  ###########################################'

        protos.each_with_index do |proto, proto_code|
          # This figures out which identifiers mentioned in the msg
          # definition must be passed in vs. declared within the method

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

        if protos.length > 0
          code << ''
          code << '  # This method is used when you\'re receiving protocol messages'
          code << '  # in an unknown order, and dispatching automatically.'
          code << '  #'
          code << "  # NOTE: while you can pass parameters into this method, if you know the"
          code << "  #       inputs to what you want to receive then you probably know what"
          code << "  #       messages you are getting. In that case, explicit recv_* method calls"
          code << "  #       are preferred, if possible. However, this method can be very"
          code << "  #       effective for streaming in read-only protocol messages."
          code << '  def recv_any(params=[])'
          code << "    case @socket.recv(1).unpack('C').first"

          protos.each_with_index do |proto, proto_code|
            code << "    when #{proto_code} then [#{proto_code}, recv_#{proto[:name]}(*params)]"
          end

          code << '    end'
          code << '  end'
        end

        code
      end
      ##
      # Builds a single protocol method
      def _proto_method(kind, proto_code, proto, local_vars, passed_params)
        code = []

        code << "  # #{proto[:desc]}" if proto[:desc]
        unless local_vars.empty?
          code << '  #'
          code << '  # returns:  (type | local var name)'
          code << '  # ['
          local_vars.uniq.each{|v| code << "  #    #{"#{v.first}".ljust(12)} | #{v.last}" }
          code << '  # ]'
        end

        code << "  def #{kind}_#{proto[:name]}#{passed_params.length > 0 ? "(#{(passed_params.to_a).join(', ')})" : ''}"

        msgs = proto[:msgs]
        code << "    w_u8(#{proto_code})" if kind.eql?('send')
        msgs.each do |msg|
          msg = kind.eql?('send') ? msg : _flip_mode(msg)
          code << "    #{_line_from_msg(msg)}"
        end
        code << "    [#{local_vars.map{|v| v.last }.uniq.join(', ')}]"
        code << "  end"

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
          "#{"#{identifier} = " if identifier}r_#{type}"
        when :write
          "w_#{type}(#{identifier})"
        else
          raise "Unsupported message msg mode: `#{mode}`"
        end
      end
    end
  end
end
