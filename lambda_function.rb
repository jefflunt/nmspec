require 'json'
load './lib/nmspec.rb'

def lambda_handler(event:, context:)

  body =  begin
            JSON.parse(event['body'])
          rescue JSON::ParserError
            return {
              statusCode: 200,
              body: JSON.generate({ err: "JSON parse error - POST body does not appear to be valid JSON" })
            }
          end

  {
    statusCode: 200,
    body: JSON.generate(
      Nmspec::V1.gen({
        'spec' => body.dig('spec'),
        'langs' => body.dig('langs'),
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
    body: JSON.generate(
      {
        err: 'Unexpected exception',
        payload_received: "#{body.to_s[..100]} ..."
      }
    ),
  }
end
