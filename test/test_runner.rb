require 'minitest'
Dir['test/**/*_test.rb'].each{|f| load f }

def nmspec_parse_and_load_demo(kind)
  puts "Reading nmspec file ..."
  nmspec = IO.read("demo/#{kind}.nmspec")

  puts "Parsing nmspec ..."
  parse_result = Nmspec::V1.gen({
    'spec' => nmspec,
    'langs' => ['ruby'],
  })

  puts "Wrting nmspec ..."
  filename = "codegen_output/#{kind}.rb"
  File.open(filename, 'w') do |f|
    f.puts parse_result.dig('code', 'ruby')
  end

  puts "Loading resulting code ..."
  load filename
end
