require 'minitest'
Dir['test/**/*_test.rb'].each{|f| load f }

def nmspec_parse_and_load_demo(kind)
  nmspec = IO.read("demo/#{kind}.nmspec")

  parse_result = Nmspec::V1.gen({
    'spec' => nmspec,
    'langs' => ['ruby'],
  })

  filename = "codegen_output/#{kind}.rb"
  File.open(filename, 'w') do |f|
    f.puts parse_result.dig('code', 'ruby')
  end

  load filename
  parse_result
end
