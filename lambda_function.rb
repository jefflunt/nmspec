require 'json'
require 'nmspec'

def lambda_handler(event:, context:)
  { statusCode: 200, body: JSON.generate({ msg: 'nmspec on lambda' }) }
end

puts lambda_handler(event: {}, context: {})
