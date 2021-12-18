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
        code << _list_types

        types = spec['types']
        if types
          code << _subtype_aliases(types)
          code << '' if types.length > 0
        end

        code << _msgs_methods(spec['msgs'])

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

      # This includes str, and anything with '*_list' in the type name
      def _list_types
        code = []

        code << '  ###########################################'
        code << '  # list types'
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

        ::Nmspec::V1::BASE_TYPES
          .each do |type|
            # See https://www.rubydoc.info/stdlib/core/1.9.3/Array:pack
            num_bytes, pack_type =  case type
                                    when 'float_list'
                                      [4, 'g']
                                    when 'double_list'
                                      [8, 'G']
                                    when 'i8_list','u8_list'
                                      [1, type.start_with?('i') ? 'c' : 'C']
                                    when 'i16_list','u16_list'
                                      [2, type.start_with?('i') ? 's>' : 'S>']
                                    when 'i32_list','u32_list'
                                      [4, type.start_with?('i') ? 'l>' : 'L>']
                                    when 'i64_list','u64_list'
                                      [8, type.start_with?('i') ? 'q>' : 'Q>']
                                    else
                                      next
                                    end

            code << _type_list_reader_writer_methods(type, num_bytes, pack_type)
          end

        code
      end

      def _type_list_reader_writer_methods(type, num_bytes, pack_type=nil)
        code = []

        send_contents = pack_type ?  "([#{type}].pack('#{pack_type}*'), 0)" : "(#{type}, 0)"
        recv_contents = pack_type ? "(#{num_bytes}).unpack('#{pack_type}')" : "(#{num_bytes})"

        code << "  def r_#{type}"
        code << "    @socket.recv#{recv_contents}"
        code << '  end'
        code << ''
        code << "  def w_#{type}(#{type})"
        code << "    raise \"Cannot send #{type} longer than 16k elements\" if #{type}.length > 2**16"
        code << ''
        code << "    @socket.send([#{type}.length].pack('Q>'), 0)"
        code << "    @socket.send#{send_contents} }"
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
      def _msgs_methods(msgs)
        code = []

        code << '  ###########################################'
        code << '  # messages'
        code << '  ###########################################'

        msgs.keys.each_with_index do |msg_name, msg_code|
          # This figures out which identifiers mentioned in the msg
          # definition must be passed in vs. declared within the method

          next if msgs[msg_name]['steps'].empty?

          code << ''
          send_local_vars = []
          recv_local_vars = []
          send_passed_params, recv_passed_params = msgs[msg_name]['steps']
            .inject([Set.new, Set.new]) do |all_params, step|
              send_params, recv_params = all_params
              mode, type, identifier = step.split

              case mode
              when 'r'
                send_local_vars << [type, identifier]
                recv_params << identifier unless send_local_vars.map{|v| v.last}.include?(identifier)
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
          code << _msg_method('send', msg_name, msgs, send_local_vars, send_passed_params, msg_code)
          code << ''
          code << _msg_method('recv', msg_name, msgs, recv_local_vars, recv_passed_params, msg_code)
        end

        code
      end
      ##
      # Builds a single msg method
      def _msg_method(kind, msg_name, msgs, local_vars, passed_params, msg_code)
        code = []

        code << "  # #{msgs[msg_name]['desc']}" if msgs[msg_name]['desc']
        unless local_vars.empty?
          code << '  #'
          code << '  # returns:  (type | local var name)'
          code << '  # ['
          local_vars.uniq.each{|v| code << "  #    #{"#{v.first}".ljust(12)} | #{v.last}" }
          code << '  # ]'
        end

        code << "  def #{kind}_#{msg_name}#{passed_params.length > 0 ? "(#{(passed_params.to_a).join(', ')})" : ''}"

        steps = msgs[msg_name]['steps']
        code << "    w_i8(#{msg_code})" if kind.eql?('send')
        steps.each do |step|
          step = kind.eql?('send') ? step : _flip_mode(step)
          code << "    #{_line_from_step(step)}"
        end
        code << "\n    [#{local_vars.map{|v| v.last }.uniq.join(', ')}]" unless local_vars.empty?
        code << "  end"

        code
      end

      def _flip_mode(step)
        mode, type, identifier = step.split(' ')
        "#{mode == 'r' ? 'w' : 'r'} #{type} #{identifier}"
      end

      def _line_from_step(step)
        mode, type, identifier = step.split(' ')

        case mode
        when 'r'
          "#{"#{identifier} = " if identifier}r_#{type}"
        when 'w'
          "w_#{type}(#{identifier})"
        else
          raise "Unsupported message step mode: `#{mode}`"
        end
      end
    end
  end
end
