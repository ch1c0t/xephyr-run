def socket_path : String
  @@socket_path
end

def amqp_channel : ::AMQP::Client::Channel
  @@amqp_channel ||= Global::AMQP.create_channel(Global.socket_path)
end
