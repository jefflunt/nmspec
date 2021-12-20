require 'minitest/autorun'
require 'socket'
require_relative '../lib/nmspec'

class TestBaseTypes < Minitest::Test
  TEST_PORT = 9834

  def setup
    begin
      parse_result = nmspec_parse_and_load_demo('base_types')
    rescue => e
      puts "Failed to eval code: `#{parse_result.inspect}`"
    end

    @server = Process.fork {
      tcp_server = TCPServer.new(TEST_PORT)
      loop do
        client = tcp_server.accept
        msgr = BaseTypesMsgr.new(client)
        proto_code, recv_data = msgr.recv_any
        msgr.send_any(proto_code, recv_data)
      end
    }

    Process.detach(@server)

    # Client socket
    conn_tries = 0
    @conn = loop do
              begin
                break TCPSocket.new('localhost', TEST_PORT)
              rescue
                break 'Failed to connect' if conn_tries == 3
                conn_tries += 1
                sleep 0.5
              end
            end

    @client_msgr = BaseTypesMsgr.new(@conn)
  end

  def teardown
    @conn.close
    Process.kill 'HUP', @server
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
      3.140000104904175,
      [3.140000104904175, 4.139999866485596, 5.139999866485596],
      Float::MIN,
      [Float::MIN, Float::MIN + 1, Float::MIN + 2],
      'test string',
      ['test string 1', 'test string 2', 'test string 3']
    ]

    @client_msgr.send_all_base_types(*send_data)
    @conn.recv(1) # read and discard msg_code
    recv_data = @client_msgr.recv_all_base_types

    assert_equal(send_data, recv_data)
  end
end
