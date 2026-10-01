module Xephyr
  class Client
    def initialize(@request : Xephyr::Request)
      @channel = Global.amqp_channel
      @response_bridge = Channel(String).new
      @queue_name = "#{Process.pid}.xephyr_commands.out"
    end

    def execute : Xephyr::Response
      response_queue = @channel.queue(
        @queue_name,
        auto_delete: true,
        exclusive: true
      )

      response_queue.subscribe(no_ack: true) do |msg|
        @response_bridge.send(msg.body_io.to_s)
      end

      @channel.basic_publish(
        @request.to_json,
        exchange: "",
        routing_key: "xephyr_commands",
        props: AMQP::Client::Properties.new(reply_to: @queue_name)
      )

      Xephyr::Response.from_json(@response_bridge.receive)
    end
  end
end
