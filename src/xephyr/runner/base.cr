module Xephyr
  class Runner
    class InvalidRequestError < Exception
    end

    class MissingReplyToError < Exception
    end

    @@display_counter = Atomic(Int32).new(10)
    @@sessions = Hash(String, Xephyr::Session).new

    @channel : ::AMQP::Client::Channel

    def initialize(@message : AMQP::Client::DeliverMessage)
      @channel = Global.amqp_channel
    end
  end
end
