class XephyrRunner
  class InvalidRequestError < Exception
  end

  class MissingReplyToError < Exception
  end

  @@display_counter = Atomic(Int32).new(10)
  @@sessions = Hash(String, XephyrSession).new

  @channel : ::AMQP::Client::Channel

  def initialize(@message : AMQP::Client::DeliverMessage)
    @channel = Global.amqp_channel
  end
end
