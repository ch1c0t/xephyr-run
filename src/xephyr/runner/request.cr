module Xephyr
  class Runner
    def run
      request = Xephyr::Request.from_json(@message.body_io.to_s)
      return invalid_request unless request.valid?
      case request.action
      when Xephyr::Request::START
        start_session(request.command.not_nil!)
      when Xephyr::Request::KILL
        kill_session(request.display.not_nil!)
      else
        send_reply(Xephyr::Response.new(
          status: Xephyr::Response::ERROR,
          error: "Unsupported action: #{request.action}"
        ))
      end
    rescue JSON::ParseException
      send_reply(Xephyr::Response.new(
        status: Xephyr::Response::ERROR, error: "Invalid JSON request"
      ))
    rescue ex : MissingReplyToError
      STDERR.puts "Cannot reply to xephyr request: #{ex.message}"
    rescue ex : Exception
      send_reply(Xephyr::Response.new(
        status: Xephyr::Response::ERROR,
        error: ex.message || "Xephyr daemon failure"
      ))
      STDERR.puts "Xephyr daemon failure: #{ex.message}"
    end
    private def invalid_request
      send_reply(Xephyr::Response.new(
        status: Xephyr::Response::ERROR, error: "Invalid xephyr request"
      ))
    end
  end
end
