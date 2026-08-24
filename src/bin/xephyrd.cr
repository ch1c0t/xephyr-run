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

socket_path = Path.home.join(".local/share/redis/redis.sock").to_s

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
  end
end
