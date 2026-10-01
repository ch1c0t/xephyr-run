require "./global"
require "json"

module Xephyr
  struct Request
    include JSON::Serializable

    START = "START"
    KILL  = "KILL"

    property action : String
    property command : String?
    property display : String?

    def initialize(
      @action : String,
      @command : String? = nil,
      @display : String? = nil
    )
    end

    def valid? : Bool
      case action
      when START
        !command.nil? && !command.not_nil!.empty?
      when KILL
        !display.nil? && !display.not_nil!.empty?
      else
        false
      end
    end
  end

  struct Response
    include JSON::Serializable

    SUCCESS = "SUCCESS"
    ERROR   = "ERROR"

    property status : String
    property display : String?
    property error : String?

    def initialize(
      @status : String,
      @display : String? = nil,
      @error : String? = nil
    )
    end

    def success? : Bool
      status == SUCCESS
    end
  end

  class Client
    def initialize(@command_string : String)
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

      request = Xephyr::Request.new(
        action: Xephyr::Request::START,
        command: @command_string
      )

      @channel.basic_publish(
        request.to_json,
        exchange: "",
        routing_key: "xephyr_commands",
        props: AMQP::Client::Properties.new(reply_to: @queue_name)
      )

      Xephyr::Response.from_json(@response_bridge.receive)
    end
  end
end
