require 'minitest/autorun'
require 'socket'
require_relative '../lib/nmspec'

class TestBaseTypes < Minitest::Test
  TEST_PORT = 9834

  def setup
    eval(
      Nmspec::V1.gen({
        'spec' => IO.read('demo/base_types.nmspec'),
        'langs' => ['ruby'],
      })['code']['ruby']
    )

    Thread.new do
      loop do
        @server = TCPServer.new(TEST_PORT)
        client = @server.accept
        @recv_data = BaseTypesMsgr
                      .new(client)
                      .recv_all_base_types
        client.close
      end
    end
  end

  def teardown
    @server.close
  end

  def test_send_all_base_types
    send_data = [
      -1,
      1,
      [1, 2, 3]
    ]

    s = TCPSocket.new('localhost', TEST_PORT)
    BaseTypesMsgr
      .new(s)
      .sent_all_base_types(*send_data)
    s.close

    assert_equal(send_data, @recv_data)
  end
end
