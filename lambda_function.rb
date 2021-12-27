require 'json'
load './lib/nmspec.rb'

def lambda_handler(event:, context:)
  { statusCode: 200, body: JSON.generate({ msg: 'nmspec on lambda' }) }
end
