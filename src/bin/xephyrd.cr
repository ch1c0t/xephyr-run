require "./xephyrd/*"

VERSION = "0.0.0"

case ARGV.size
when 1
  case ARGV[0]
  when "-v", "version", "--version"
    puts VERSION
    exit
  when "-h", "help", "--help"
    print_help
    exit
  end
end

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


# Helper function to write failure logs to both the console and a physical log file
def log_application_failure(app_name : String, display_string : String, exit_code : Int32, error_logs : String)
  # 1. Build destination path: ~/.local/state/xephyrd/
  state_dir = Path.home.join(".local", "state", "xephyrd")
  Dir.mkdir_p(state_dir) # Creates the directory path safely if it is missing

  # 2. Generate a unique filename using timestamp and display id
  timestamp = Time.local.to_s("%Y%m%d_%H%M%S")
  safe_display = display_string.gsub(':', "")
  log_filename = "#{timestamp}_#{app_name}_#{safe_display}.log"
  log_filepath = state_dir.join(log_filename)

  # 3. Format the complete diagnostic report payload
  report = String.build do |io|
    io << "CRASH REPORT\n"
    io << "Time:          #{Time.local}\n"
    io << "Application:   #{app_name}\n"
    io << "Display:       #{display_string}\n"
    io << "Exit Code:     #{exit_code}\n"
    io << "Captured Logs:\n"
    io << (error_logs.empty? ? "[No stderr logs emitted]" : error_logs)
  end

  # 4. Write data out to the physical file system path
  File.write(log_filepath, report)

  # 5. Print matching error info out to standard error stream (STDERR)
  STDERR.puts "\n[!] CRASH DETECTED: Application '#{app_name}' failed on #{display_string} (Exit Code: #{exit_code})."
  STDERR.puts "    Log saved to: #{log_filepath}"
  if !error_logs.strip.empty?
    STDERR.puts "    Captured Output Logs:\n--- Start App Logs ---\n#{error_logs.strip}\n--- End App Logs ---"
  end
end


# Helper function to dynamically discover the current screen resolution via xrandr
def screen_resolution : String
  stdout_buffer = IO::Memory.new
  status = Process.run("xrandr", args: ["--current"], output: stdout_buffer)

  if status.success?
    output_string = stdout_buffer.to_s
    if match = output_string.match(/\b(\d+)x(\d+)\b/)
      return match[0]
    end
  end

  # Safe hardcoded fallback if xrandr is missing or fails to parse
  "1024x768"
end

require "redis"

default_fallback = Path.home.join(".local/share/redis/socket").to_s
socket_path = ENV.fetch("REDIS_UNIXSOCKET", default_fallback)

puts "Connecting to Redis via Unix socket at: #{socket_path}"

# 2. Initialize crystal-redis using the verified 'unixsocket' parameter
redis = Redis.new(unixsocket: socket_path)

channel = "Xephyr"
puts "Listening for messages on channel '#{channel}'..."
puts "Press Ctrl+C to exit."

# 3. Block and listen for incoming messages on the channel
# The block yields the channel name and the string message payload
redis.subscribe(channel) do |on|
  on.message do |_channel, message|
    runner = XephyrRunner.new(message)
    runner.run if runner.valid?
  end
end
