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

require "redis"

display_counter = Atomic(Int32).new(10)

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
  on.message do |subscription_channel, message|
    puts "[#{Time.local}] Received from #{subscription_channel}: #{message}"
    raw_payload = message.strip
    next if raw_payload.empty?

    display_id = display_counter.add(1)
    display_string = ":#{display_id}"
    puts "\n[+] Received Command: '#{raw_payload}' -> Spawning isolated screen #{display_string}"

    spawn do
      begin
        # Split message into application executable and its positional arguments
        parts = raw_payload.split(' ')
        app_executable = parts.shift
        app_args = parts

        xephyr_process = Process.new(
          command: "Xephyr", 
          args: [display_string, "-screen", "800x600", "-ac"]
        )

        sleep 500.milliseconds

        app_process = Process.new(
          command: app_executable,
          args: app_args,
          env: {"DISPLAY" => display_string}
        )

        puts "[-] Screen #{display_string} Operational. Running PID #{app_process.pid}"

        # C. Non-blocking wait for the target application layer to exit
        app_process.wait
        puts "[x] Program inside #{display_string} closed. Cleaning up Xephyr process..."
        xephyr_process.terminate if xephyr_process.exists?
      rescue ex : Exception
        STDERR.puts "Error processing layout target '#{raw_payload}': #{ex.message}"
      end
    end
  end
end
