require 'minitest'
require 'yaml'

require_relative '../lib/nmspec/v1'
require_relative '../lib/nmspec/parser'
require_relative '../lib/nmspec/ruby3x'
require_relative '../lib/nmspec/gdscript3x.rb'

Dir['test/**/*_test.rb'].each{|f| load f }

def nmspec_parse_and_load_demo(kind)
  nmspec = IO.read("demo/#{kind}.nmspec")

  parse_result = Nmspec::V1.gen({
    'spec' => nmspec,
    'langs' => ['ruby3x'],
  })

  filename = "generated_code/#{kind}.rb"
  File.open(filename, 'w') do |f|
    f.puts parse_result.dig('code', 'ruby3x')
  end

  load filename
  parse_result
end
