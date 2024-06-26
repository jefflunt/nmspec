require 'yaml'
require_relative './version.rb'

module Nmspec
  module V1
    SUPPORTED_SPEC_VERSIONS = [1]
    SUPPORTED_OUTPUT_LANGS = %w(gdscript3x ruby3x)
    GEN_OPTS_KEYS = %w(langs spec)
    REQ_KEYS = %w(version msgr)
    OPT_KEYS = %w(types protos)
    BASE_TYPES = %w(
                    i8 u8   i8_list  u8_list
                    i16 u16 i16_list u16_list
                    i32 u32 i32_list u32_list
                    i64 u64 i64_list u64_list
                    float   float_list
                    double  double_list
                    str     str_list
                 )

    STR_TYPE_PATTERN = /\Astr[0-9]+\Z/
    IDENTIFIER_PATTERN = /\A[_a-zA-Z][_a-zA-Z0-9]*\Z/
    VALID_STEP_MODES = %w(r w)

    class << self
      # Accepts a hash of options following this format:
      #
      # {
      #   'spec' => <String of valid nmspec YAML,
      #   'langs' => ['ruby3x', ...],   # array of target languages
      # }
      #
      # Returns a hash with this format:
      def gen(opts)
        errors = []
        warnings = []

        errors << "invalid opts (expecting Hash, got #{opts.class})" unless opts.is_a?(Hash)
        errors << "unexpected keys in nmspec: [#{(opts.keys - GEN_OPTS_KEYS).join(', ')}]" unless (opts.keys - GEN_OPTS_KEYS).empty?
        errors << '`spec` key mising from nmspec options' unless opts.has_key?('spec')
        errors << "invalid spec (expecting valid nmspec YAML)" unless opts.dig('spec').is_a?(String)
        errors << '`langs` key missing' unless opts.has_key?('langs')
        errors << 'list of output languages cannot be empty' if opts.dig('langs')&.empty?
        errors << "invalid list of output languages (expecting array of strings)" unless opts.dig('langs').is_a?(Array) && opts.dig('langs').all?{|l| l.is_a?(String) }
        errors << "invalid output language(s): [#{(opts.dig('langs') || []).select{|l| !SUPPORTED_OUTPUT_LANGS.include?(l) }.join(', ') }] - valid options are [#{SUPPORTED_OUTPUT_LANGS.map{|l| "\"#{l}\"" }.join(', ')}]" unless opts.dig('langs')&.all?{|l| SUPPORTED_OUTPUT_LANGS.include?(l) }

        begin
          YAML.load(opts['spec']).is_a?(Hash)
        rescue TypeError
          errors << "invalid nmspec YAML, check format"
        end

        return ({
          'nmspec_lib_version' => NMSPEC_GEM_VERSION,
          'valid' => false,
          'errors' => errors,
          'warnings' => warnings,
          'code' => {}
        }) unless errors.empty?

        raw_spec = YAML.load(opts['spec'])
        langs = opts['langs']

        raise "spec failed to parse as valid YAML" unless raw_spec

        valid = Nmspec::V1.valid?(raw_spec)
        errors = Nmspec::V1.errors(raw_spec)
        warnings = Nmspec::V1.warnings(raw_spec)

        spec_hash = Nmspec::Parser.parse(raw_spec)
        code = langs.each_with_object({}) do |lang, hash|
          hash[lang] = send("to_#{lang}", spec_hash)
          hash
        end

        {
          'nmspec_lib_version' => NMSPEC_GEM_VERSION,
          'valid' => valid,
          'errors' => errors,
          'warnings' => warnings,
          'code' => code
        }
      end

      def errors(raw_spec)
        [].tap do |errors|
          ##
          # main keys
          REQ_KEYS.each do |k|
            errors << "required key `#{k}` is missing" unless raw_spec.has_key?(k)
          end

          unsupported_keys = raw_spec.keys - REQ_KEYS - OPT_KEYS
          errors << "spec contains unsupported keys: [#{unsupported_keys.join(', ')}]" unless unsupported_keys.empty?

          ##
          # msgr validation
          errors << "invalid msgr name" unless _valid_msgr_name?(raw_spec['msgr'])
          errors << 'msgr is missing a name' unless raw_spec['msgr'].is_a?(Hash) && raw_spec['msgr'].has_key?('name')

          ##
          # version check
          errors << "unsupported spec version: `#{raw_spec['version']}`" unless SUPPORTED_SPEC_VERSIONS.include?(raw_spec['version'])
          errors << "spec version must be a number" unless raw_spec['version'].is_a?(Integer)

          ##
          # type validation
          all_types = BASE_TYPES.dup
          raw_spec['types']&.each do |type_spec|
            type, name = type_spec.split

            errors << "invalid type name `#{name}`" unless name =~ IDENTIFIER_PATTERN
            if _valid_type?(type, all_types)
              all_types << name
            else
              errors << "type `#{name}` has an invalid subtype of `#{type}`"
            end
          end

          ##
          # msg validation
          protos = raw_spec['protos']
          protos&.each do |proto|
            errors << "invalid msg name `#{proto['name']}`" unless proto['name'] =~ IDENTIFIER_PATTERN
            proto['msgs'] || [].each do |msg|
              mode, type, identifier = msg.split.map(&:strip)
              short_msg = [mode, type, identifier].join(' ')
              errors << "msg `#{proto['name']}`, msg `#{short_msg}` has invalid type: `#{type}`" unless _valid_type?(type, all_types)

              case mode
              when 'r'
                errors << "reader protocol `#{proto['name']}`, msg `#{short_msg}` has missing identifier" if identifier.to_s.empty?
                errors << "reader protocol `#{proto['name']}`, msg `#{short_msg}` has invalid identifier: `#{identifier}`" unless identifier =~ IDENTIFIER_PATTERN
              when 'w'
                errors << "writer protocol `#{proto['name']}`, msg `#{short_msg}` has missing identifier" if identifier.to_s.empty?
                errors << "writer msg `#{proto['name']}`, msg `#{short_msg}` has invalid identifier: `#{identifier}`" unless identifier =~ IDENTIFIER_PATTERN
              else
                errors << "protocol `#{proto['name']}` has invalid read/write mode (#{mode}) - msg: `#{short_msg}`" unless VALID_STEP_MODES.include?(mode)
              end
            end
          end
        end
      end

      def warnings(raw_spec)
        [].tap do |warnings|
          warnings << 'msgr is missing a description' unless raw_spec['msgr'].is_a?(Hash) && raw_spec['msgr'].has_key?('desc')

          raw_spec['protos']&.each do |proto|
            warnings << "protocol `#{proto['name']}` has no msgs" if proto['msgs']&.empty?
            warnings << "msg `#{proto['name']}` is missing a description" unless proto.has_key?('desc')
          end
        end
      end

      def valid?(raw_spec)
        errors(raw_spec).empty?
      end

      def to_ruby3x(spec_hash)
        ::Nmspec::Ruby3x.gen(spec_hash)
      rescue
        'codegen failure'
      end

      def to_gdscript3x(spec_hash)
        ::Nmspec::GDScript3x.gen(spec_hash)
      rescue
        'codegen failure'
      end

      def _valid_type?(type, all_types)
        all_types.include?(type) || _sub_type?(type, all_types)
      end

      def _valid_msgr_name?(mod)
        return false unless mod.is_a?(Hash)
        mod['name'] =~ /\A[a-zA-Z][a-zA-Z_0-9\s]+\Z/
      end

      def _sub_type?(type, all_types_so_far)
        return false unless type.is_a?(String)

        type =~ /\A(#{all_types_so_far.join('|')})[0-9]*\Z/
      end
    end
  end
end
