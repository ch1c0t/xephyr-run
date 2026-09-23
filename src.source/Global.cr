@@socket_path : String = begin
  path = ENV["LAVINMQ_AMQP_UNIXSOCKET"]?
  raise "Missing critical environment configuration variable: LAVINMQ_AMQP_UNIXSOCKET" if path.nil?
  path
end

@@amqp_channel : ::AMQP::Client::Channel? = nil

extend Getters
