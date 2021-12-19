require 'set'

# Nmspec code generator for ruby
module Nmspec
  module Ruby
    class << self
      def gen(spec)
        code = []
        code << '##'
        code << '# NOTE: this code is auto-generated from an nmspec file'

        if spec['msgr']['desc']
          code << '#'
          code << "# #{spec['msgr']['desc']}"
        end

        code << "class #{_class_name_from_mod(spec['msgr'])}"

        code << _constructor
        code << ''
        code << _numeric_types
        code << _str_types
        code << _list_types

        types = spec['types']
        if types
          code << _subtype_aliases(types)
          code << '' if types.length > 0
        end

        code << _protos_methods(spec['protos'])

        code << "end"

        code.join("\n")
      rescue => e
        "Code generation failed due to unknown error: check spec validity\n  cause: #{e.inspect}"
        puts e.backtrace.join("\n  ")
      end

      def _class_name_from_mod(mod)
        mod['name']
          .downcase
          .split(' ')
          .map{|part| part.capitalize}
          .join + 'Msgr'
      end

      def _constructor
        code = []
        code << '  def initialize(socket)'
        code << '    @socket = socket'
        code << '  end'
        code
      end

      def _subtype_aliases(types)
        code = []

        code << '  ###########################################'
        code << '  # subtype aliases'
        code << '  ###########################################'
        code << ''
        types.each do |subtype, basetype|
          code << "  alias_method :r_#{subtype}, :r_#{basetype}"
          code << "  alias_method :w_#{subtype}, :w_#{basetype}"
        end

        code
      end

      ##
      # inserts the boilerplate base type readers and writers
      def _numeric_types
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
                                      [4, 'g']
                                    when 'double'
                                      [8, 'G']
                                    when 'i8','u8'
                                      [1, type.start_with?('i') ? 'c' : 'C']
                                    when 'i16','u16'
                                      [2, type.start_with?('i') ? 's>' : 'S>']
                                    when 'i32','u32'
                                      [4, type.start_with?('i') ? 'l>' : 'L>']
                                    when 'i64','u64'
                                      [8, type.start_with?('i') ? 'q>' : 'Q>']
                                    else
                                      next
                                    end

            code << _type_reader_writer_methods(type, num_bytes, pack_type)
          end

        code
      end

      def _str_types
        code = []

        code << '  ###########################################'
        code << '  # str types'
        code << '  ###########################################'
        code << ''
        code << "  def r_str"
        code << "    bytes = @socket.recv(2).unpack('S>')"
        code << "    str = @socket.recv(bytes)"
        code << ''
        code << "    [str]"
        code << '  end'
        code << ''
        code << "  def w_str(str)"
        code << "    raise \"Cannot send string longer than 16k bytes\" if str.bytes.length > 2**16"
        code << ''
        code << "    @socket.send([str.length].pack('S>'), 0)"
        code << "    @socket.send(str, 0)"
        code << '  end'
        code << ''

        code
      end

      # This includes str, and anything with '*_list' in the type name
      def _list_types
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
                                      [4, 'g']
                                    when 'double_list'
                                      [8, 'G']
                                    when 'i8_list','u8_list'
                                      [1, type.start_with?('i') ? 'c*' : 'C*']
                                    when 'i16_list','u16_list'
                                      [2, type.start_with?('i') ? 's>*' : 'S>*']
                                    when 'i32_list','u32_list'
                                      [4, type.start_with?('i') ? 'l>*' : 'L>*']
                                    when 'i64_list','u64_list'
                                      [8, type.start_with?('i') ? 'q>*' : 'Q>*']
                                    else
                                      next
                                    end

            code << _type_list_reader_writer_methods(type, num_bytes, pack_type)
          end

        code
      end

      def _type_list_reader_writer_methods(type, num_bytes, pack_type=nil)
        code = []

        send_contents = pack_type ?  "(#{type}.pack('#{pack_type}'), 0)" : "(#{type}, 0)"
        recv_contents = pack_type ? "(#{num_bytes} * #{type}.length).unpack('#{pack_type}')" : "(#{num_bytes})"

        code << "  def r_#{type}"
        code << "    @socket.recv#{recv_contents}"
        code << '  end'
        code << ''
        code << "  def w_#{type}(#{type})"
        code << "    raise \"Cannot send #{type} longer than 16k elements\" if #{type}.length > 2**16"
        code << ''
        code << "    @socket.send([#{type}.length].pack('Q>'), 0)"
        code << "    @socket.send#{send_contents}"
        code << '  end'
        code << ''

        code
      end

      def _type_reader_writer_methods(type, num_bytes, pack_type=nil)
        code = []

        send_contents = pack_type ?  "([#{type}].pack('#{pack_type}'), 0)" : "(#{type}, 0)"
        recv_contents = pack_type ? "(#{num_bytes}).unpack('#{pack_type}')" : "(#{num_bytes})"

        code << "  def r_#{type}"
        code << "    @socket.recv#{recv_contents}"
        code << '  end'
        code << ''
        code << "  def w_#{type}(#{type})"
        code << "    @socket.send#{send_contents}"
        code << '  end'
        code << ''

        code
      end

      ##
      # builds all msg methods
      def _protos_methods(protos)
        code = []

        return code unless protos&.keys && protos&.keys&.length > 0

        code << '  ###########################################'
        code << '  # messages'
        code << '  ###########################################'

        protos&.keys&.each_with_index do |proto_name, proto_code|
          # This figures out which identifiers mentioned in the msg
          # definition must be passed in vs. declared within the method

          next unless protos[proto_name].has_key?('msgs') && !protos[proto_name]['msgs'].empty?

          code << ''
          send_local_vars = []
          recv_local_vars = []
          send_passed_params, recv_passed_params = protos.dig(proto_name, 'msgs')
            .inject([Set.new, Set.new]) do |all_params, msg|
              send_params, recv_params = all_params
              mode, type, identifier = msg.split

              case mode
              when 'r'
                send_local_vars << [type, identifier]
                recv_params << identifier unless recv_local_vars.map{|v| v.last}.include?(identifier)
              when 'w'
                recv_local_vars << [type, identifier]
                send_params << identifier unless send_local_vars.map{|v| v.last}.include?(identifier)
              else
                raise "Unsupported mode: `#{mode}`"
              end

              [send_params, recv_params]
            end

          ##
          # send
          code << _proto_method('send', proto_name, protos, send_local_vars, send_passed_params, proto_code)
          code << ''
          code << _proto_method('recv', proto_name, protos, recv_local_vars, recv_passed_params, proto_code)
        end

        code
      end
      ##
      # Builds a single protocol method
      def _proto_method(kind, proto_name, protos, local_vars, passed_params, proto_code)
        code = []

        code << "  # #{protos[proto_name]['desc']}" if protos[proto_name]['desc']
        unless local_vars.empty?
          code << '  #'
          code << '  # returns:  (type | local var name)'
          code << '  # ['
          local_vars.uniq.each{|v| code << "  #    #{"#{v.first}".ljust(12)} | #{v.last}" }
          code << '  # ]'
        end

        code << "  def #{kind}_#{proto_name}#{passed_params.length > 0 ? "(#{(passed_params.to_a).join(', ')})" : ''}"

        msgs = protos[proto_name]['msgs']
        code << "    w_i8(#{proto_code})" if kind.eql?('send')
        msgs.each do |msg|
          msg = kind.eql?('send') ? msg : _flip_mode(msg)
          code << "    #{_line_from_msg(msg)}"
        end
        code << "\n    [#{local_vars.map{|v| v.last }.uniq.join(', ')}]" unless local_vars.empty?
        code << "  end"

        code
      end

      def _flip_mode(msg)
        mode, type, identifier = msg.split(' ')
        "#{mode == 'r' ? 'w' : 'r'} #{type} #{identifier}"
      end

      def _line_from_msg(msg)
        mode, type, identifier = msg.split(' ')

        case mode
        when 'r'
          "#{"#{identifier} = " if identifier}r_#{type}"
        when 'w'
          "w_#{type}(#{identifier})"
        else
          raise "Unsupported message msg mode: `#{mode}`"
        end
      end
    end
  end
end