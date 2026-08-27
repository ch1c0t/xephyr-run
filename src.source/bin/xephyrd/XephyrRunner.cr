# Handles the validation, lifecycle, and crash logging of Xephyr environments
class XephyrRunner
  # Track display indices across all instances concurrently using an atomic counter
  @@display_counter = Atomic(Int32).new(10)

  def initialize(@raw_payload : String)
    @parts = @raw_payload.strip.split(' ')
    @app_executable = @parts.shift? || ""
    @app_args = @parts
    @resolved_path = nil : String?
  end

  # Validates that the payload is well-formed and the executable exists
  def valid? : Bool
    return false if @app_executable.empty?
    
    @resolved_path = Process.find_executable(@app_executable)
    if @resolved_path.nil?
      STDERR.puts "\n[!] Rejected: Program '#{@app_executable}' is not installed or not in PATH."
      return false
    end
    
    true
  end

  # Spawns Xephyr and the nested application inside a separate concurrent context
  def run
    # Ensure verification passed before spinning up infrastructure
    path = @resolved_path
    return if path.nil?

    display_id = @@display_counter.add(1)
    display_string = ":#{display_id}"
    puts "\n[+] Validated: #{path} -> Spawning screen #{display_string} [Size: #{screen_resolution}]"

    spawn do
      app_stderr_buffer = IO::Memory.new
      
      begin
        xephyr_process = Process.new(
          command: "Xephyr", 
          args: [display_string, "-screen", screen_resolution, "-ac"]
        )

        sleep 100.milliseconds

        app_process = Process.new(
          command: path,
          args: @app_args,
          env: {"DISPLAY" => display_string},
          error: app_stderr_buffer
        )

        puts "[-] Screen #{display_string} Operational. Running PID #{app_process.pid}"

        exit_status = app_process.wait
        if exit_status.success?
          puts "[x] Program inside #{display_string} closed. Cleaning up Xephyr process..."
        else
          log_application_failure(
            @app_executable,
            @raw_payload,
            display_string,
            exit_status.exit_code,
            app_stderr_buffer.to_s
          )
        end

        xephyr_process.terminate if xephyr_process.exists?
      rescue ex : Exception
        STDERR.puts "System execution failure inside target '#{@raw_payload}': #{ex.message}"
      end
    end
  end
end
