require "amqp-client"
require "global-amqp_channel"

module Global
  module AMQP
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
  end

  module Getters
    def socket_path : String
      @@socket_path
    end
    
    def amqp_channel : ::AMQP::Client::Channel
      @@amqp_channel ||= Global::AMQP.create_channel(Global.socket_path)
    end
  end

end