require "./xephyr"

class XephyrRunner
  class InvalidRequestError < Exception
  end

  class MissingReplyToError < Exception
  end

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

      spawn x11_stack(display, command)
    end
  end

  module X11Stack
    private def x11_stack(display : String, command : String)
      xephyr : Process? = nil
      wm : Process? = nil
      app_stderr_buffer = IO::Memory.new

      begin
        xephyr = Process.new(
          "Xephyr",
          [display, "-screen", screen_resolution, "-ac"]
        )

        wait_for_x_server(display)

        wm = Process.new(
          "matchbox-window-manager",
          ["-use_titlebar", "no"],
          env: {"DISPLAY" => display}
        )

        app = Process.new(
          "/bin/sh",
          ["-c", command],
          env: {"DISPLAY" => display},
          error: app_stderr_buffer
        )

        wait_for_process_start(app)

        unless app.exists?
          send_reply(
            Xephyr::Response.new(
              status: Xephyr::Response::ERROR,
              error: "Application failed to start"
            )
          )
          return
        end

        send_reply(
          Xephyr::Response.new(
            status: Xephyr::Response::SUCCESS,
            display: display
          )
        )

        exit_status = app.wait

        unless exit_status.success?
          log_application_failure(
            command,
            display,
            exit_status.exit_code,
            app_stderr_buffer.to_s
          )
        end
      rescue ex : Exception
        send_reply(
          Xephyr::Response.new(
            status: Xephyr::Response::ERROR,
            error: ex.message || "Server runtime failure"
          )
        )
        STDERR.puts "System execution failure for #{display}: #{ex.message}"
      ensure
        wm.try &.terminate if wm && wm.not_nil!.exists?
        xephyr.try &.terminate if xephyr && xephyr.not_nil!.exists?
      end
    end

    private def wait_for_x_server(display : String)
      100.times do
        return if Process.run(
          "xdpyinfo",
          args: ["-display", display],
          output: Process::Redirect::Close,
          error: Process::Redirect::Close
        ).success?

        sleep 50.milliseconds
      end

      raise "Xephyr did not become ready on #{display}"
    end

    private def wait_for_process_start(process : Process)
      100.times do
        return if process.exists?
        sleep 10.milliseconds
      end
    end
  end

  @@display_counter = Atomic(Int32).new(10)

  @channel : ::AMQP::Client::Channel

  def initialize(@message : AMQP::Client::DeliverMessage)
    @channel = Global.amqp_channel
  end

  include Helpers
  include X11Stack
  include Run
end
