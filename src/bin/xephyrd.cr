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

# Helper function to write failure logs to both the console and a physical log file
def log_application_failure(app_name : String, received_command : String, display_string : String, exit_code : Int32, error_logs : String)
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
    io << "Received command: #{received_command}\n"
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
require "../xephyr_runner"
redis.subscribe(channel) do |on|
  on.message do |_channel, message|
    runner = XephyrRunner.new(message)
    runner.run if runner.valid?
  end
end
