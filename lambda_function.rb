require 'json'
load './lib/nmspec.rb'

def lambda_handler(event:, context:)
  {
    statusCode: 200,
    body: JSON.generate(
      Nmspec::V1.gen({
        'spec' => event.dig('spec'),
        'langs' => event.dig('langs'),
      })
    ),
  }
rescue => e
  puts "ERR: #{e.class.name}"
  puts "ERR: #{e.message}"
  puts "ERR:"
  puts e
    .backtrace
    .map
    .with_index{|l, i| "  #{i.to_s.rjust(3)}: #{l}" }.join("\n")

  {
    statusCode: 200,
    body: JSON.generate({ err: 'Unexpected exception' }),
  }
end
