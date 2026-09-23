def self.create_channel(socket_path : String) : ::AMQP::Client::Channel
  client = ::AMQP::Client.new host: socket_path
  conn = client.connect
  ch = conn.channel

  at_exit do
    ch.close
    conn.close
  end

  ch
end
