require "./xephyr-run/*"

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

if ARGV.empty?
  STDERR.puts "Pass a command as the first argument."
  STDERR.puts "Usage: xephyr-run \"command_to_run_inside_xephyr\""
  exit 1
end

command_to_run = ARGV[0]

require "../global"
channel = Global.amqp_channel

pid = Process.pid
out_queue_name = "#{pid}.xephyr_commands.out"
response_queue = channel.queue(out_queue_name, auto_delete: true, exclusive: true)

response_bridge = Channel(String).new
response_queue.subscribe(no_ack: true) do |msg|
  response_bridge.send(msg.body_io.to_s)
end

channel.basic_publish(
  command_to_run,
  exchange: "",
  routing_key: "xephyr_commands",
  props: AMQP::Client::Properties.new(
    reply_to: response_queue.name,
  )
)

if display_name = response_bridge.receive
  puts display_name
end
