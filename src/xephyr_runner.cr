class XephyrRunner
  class BinaryNotFoundError < Exception
    def initialize(app_executable : String)
      super("Program '#{app_executable}' is not installed or not available in PATH.")
    end
  end

  module Helpers
    def response_queue : String
      queue = @message.properties.reply_to
      if queue.nil? || queue.empty?
        raise MissingReplyToError.new
      end
      queue
    end
    
    def resolved_path : String
      found_path = Process.find_executable(@app_executable)
      if found_path.nil?
        raise BinaryNotFoundError.new(@app_executable)
      end
    
      found_path
    end
    
    private def send_reply(payload_text : String)
      @channel.basic_publish(payload_text, exchange: "", routing_key: response_queue)
    end
  end

  class MissingReplyToError < Exception
  end

  module Run
    # Spawns Xephyr and the nested application inside a separate concurrent context
    def run
      display_id = @@display_counter.add(1)
      display_string = ":#{display_id}"
      puts "\n[+] Validated: #{resolved_path} -> Spawning screen #{display_string} [Size: #{screen_resolution}]"
    
      spawn x11_stack(display_string)
    end
  end

  module X11Stack
    private def x11_stack(display : String)
      begin
        app_stderr_buffer = IO::Memory.new
    
        xephyr = Process.new("Xephyr", [display, "-screen", screen_resolution, "-ac"])
        sleep 50.milliseconds
        wm = Process.new("matchbox-window-manager", ["-use_titlebar", "no"], env: {"DISPLAY" => display})
    
        app = Process.new(
          command: resolved_path,
          args: @app_args,
          env: {"DISPLAY" => display},
          error: app_stderr_buffer
        )
        sleep 50.milliseconds
    
        if app.exists?
          puts "[-]·Screen·#{display}·Operational.·Running·PID·#{app.pid}"
          send_reply(display)
    
          exit_status = app.wait
          if exit_status.success?
            puts "[x] Program inside #{display} closed. Cleaning up Xephyr process..."
          else
            log_application_failure(
              @app_executable,
              @raw_payload,
              display,
              exit_status.exit_code,
              app_stderr_buffer.to_s
            )
          end
        else
          send_reply("ERROR: Application crashed immediately on startup")
        end
    
        wm.terminate if wm.exists?
        xephyr.terminate if xephyr.exists?
      rescue ex : Exception
        send_reply("ERROR: Server runtime failure")
        STDERR.puts "System execution failure for #{display} inside target '#{@raw_payload}': #{ex.message}"
      end
    end
  end

  # Track display indices across all instances concurrently using an atomic counter
  @@display_counter = Atomic(Int32).new(10)
  
  @channel : ::AMQP::Client::Channel
  @raw_payload : String
  @app_executable : String
  @app_args : Array(String)
  @resolved_path : String?
  
  def initialize(@message : AMQP::Client::DeliverMessage)
    @channel = Global.amqp_channel
    @raw_payload = @message.body_io.to_s
  
    @parts = @raw_payload.strip.split(' ')
    @app_executable = @parts.shift? || ""
    @app_args = @parts
  end
  
  include Helpers
  include X11Stack
  include Run
end