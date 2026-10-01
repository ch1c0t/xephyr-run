require "./xephyr"
require "./xephyr_session"

class XephyrRunner
  class InvalidRequestError < Exception
  end

  class MissingReplyToError < Exception
  end

  @@display_counter = Atomic(Int32).new(10)
  @@sessions = Hash(String, XephyrSession).new

  module Helpers
    private def response_queue : String
      queue = @message.properties.reply_to
      if queue.nil? || queue.empty?
        raise MissingReplyToError.new
      end
      queue
    end

    private def send_reply(response : Xephyr::Response)
      @channel.basic_publish(
        response.to_json,
        exchange: "",
        routing_key: response_queue
      )
    end
  end

  module Run
    def run
      request = Xephyr::Request.from_json(@message.body_io.to_s)

      unless request.valid?
        send_reply(
          Xephyr::Response.new(
            status: Xephyr::Response::ERROR,
            error: "Invalid xephyr request"
          )
        )
        return
      end

      case request.action
      when Xephyr::Request::START
        start_session(request.command.not_nil!)
      else
        send_reply(
          Xephyr::Response.new(
            status: Xephyr::Response::ERROR,
            error: "Unsupported action: #{request.action}"
          )
        )
      end
    rescue JSON::ParseException
      send_reply(
        Xephyr::Response.new(
          status: Xephyr::Response::ERROR,
          error: "Invalid JSON request"
        )
      )
    rescue ex : MissingReplyToError
      STDERR.puts "Cannot reply to xephyr request: #{ex.message}"
    rescue ex : Exception
      send_reply(
        Xephyr::Response.new(
          status: Xephyr::Response::ERROR,
          error: ex.message || "Xephyr daemon failure"
        )
      )
      STDERR.puts "Xephyr daemon failure: #{ex.message}"
    end

    private def start_session(command : String)
      display_id = @@display_counter.add(1)
      display = ":#{display_id}"
      session = XephyrSession.new(display, command)

      session.start
      @@sessions[display] = session

      spawn do
        session.wait
        @@sessions.delete(display)
      end

      send_reply(
        Xephyr::Response.new(
          status: Xephyr::Response::SUCCESS,
          display: display
        )
      )
    end
  end

  @channel : ::AMQP::Client::Channel

  def initialize(@message : AMQP::Client::DeliverMessage)
    @channel = Global.amqp_channel
  end

  include Helpers
  include Run
end
