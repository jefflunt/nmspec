require 'minitest/autorun'
require 'socket'
require_relative '../lib/nmspec'

class TestBaseTypes < Minitest::Test
  TEST_PORT = 9834

  def setup
    begin
      nmspec_parse_and_load_demo('base_types')

      server = Process.fork {
        tcp_server = TCPServer.new(TEST_PORT)
        puts "#{Process.pid} starting server on #{TEST_PORT}"
        loop do
          client = tcp_server.accept
          msgr = BaseTypesMsgr.new(client)
          client.recv(1) # read and discard msg_code
          msgr.send_all_base_types(*msgr.recv_all_base_types.first)
          client.close
        end
      }

      Process.detach(server)
      sleep 1
    rescue
      puts "Failed to eval code: `#{parse_result.inspect}`"
    end
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

    s = TCPSocket.new('localhost', TEST_PORT)
    msgr = BaseTypesMsgr.new(s)
    msgr.send_all_base_types(*send_data)
    s.recv(1) # read and discard msg_code
    recv_data = msgr.recv_all_base_types.first

    puts "ASSERTING ..."
    assert_equal(send_data, recv_data)
  end
end
