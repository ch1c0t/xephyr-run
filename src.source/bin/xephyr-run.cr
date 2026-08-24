require "redis"

# 1. Check if a CLI argument was provided
if ARGV.empty?
  STDERR.puts "Error: Missing message argument."
  STDERR.puts "Usage: crystal run publisher.cr -- \"Your message here\""
  exit 1
end

# 2. Get the first command-line argument
message_to_send = ARGV[0]

# 3. Resolve the Unix socket path
socket_path = Path.home.join(".local/share/redis/redis.sock").to_s
p socket_path

# 4. Connect and publish
redis = Redis.new(unixsocket: socket_path)
channel = "Xephyr"

puts "Publishing to channel '#{channel}' via socket..."
subscribers = redis.publish(channel, message_to_send)

puts "Success! Message delivered to #{subscribers} subscriber(s)."
