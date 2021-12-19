require 'minitest/autorun'
require 'socket'
require_relative '../lib/nmspec'

class TestBaseTypes < Minitest::Test
  TEST_PORT = 9834

  def setup
    begin
      nmspec = IO.read('demo/base_types.nmspec')
      parse_result = Nmspec::V1.gen({
        'spec' => nmspec,
        'langs' => ['ruby'],
      })

      starting_classes = ObjectSpace.each_object(Class)
      eval(parse_result['code']['ruby'])
    rescue
      puts "Failed to eval code: `#{parse_result.inspect}`"
    end

#    @server_thread = Thread.new do
#      begin
#        loop do
#          @server = TCPServer.new(TEST_PORT)
#          client = @server.accept
#          @recv_data = BaseTypesMsgr
#                        .new(client)
#                        .recv_all_base_types
#          client.close
#        end
#      rescue IOError
#        puts "Exiting due to IOError"
#      end
#    end
  end

  def teardown
    @server.close
  end

  def test_send_all_base_types
    send_data = [
      -1,
      255,
      [-1, -2, -3],
      [253, 254, 255],
      -16_000,
      32_000,
      [-16_000, -16_001, -16_002],
      [32_000, 32_001, 32_002],
      -2_100_000_000,
      4_200_000_000,
      [-2_100_000_000, -2_100_000_001, -2_100_000_002],
      [4_200_000_000, 4_200_000_001, 4_200_000_002],
      -9_000_000_000_000_000_000,
      18_000_000_000_000_000_000,
      [-9_000_000_000_000_000_000, -9_000_000_000_000_000_001, -9_000_000_000_000_000_002],
      [18_000_000_000_000_000_000, 18_000_000_000_000_000_001, 18_000_000_000_000_000_002],
      3.14,
      [3.14, 4.14, 5.14],
      Float::MIN,
      [Float::MIN, Float::MIN + 1, Float::MIN + 2],
      'test string',
      ['test string 1', 'test string 2', 'test string 3']
    ]

    server = TCPServer.new(TEST_PORT)

    s = TCPSocket.new('localhost', TEST_PORT)
    client = server.accept
    recv_data = BaseTypesMsgr
                  .new(client)
                  .recv_all_base_types
    client.close
    server.close

    BaseTypesMsgr
      .new(s)
      .send_all_base_types(*send_data)
    s.close

    Thread.pass

    assert_equal(send_data, recv_data)
  end
end
