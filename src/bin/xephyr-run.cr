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

require "../xephyr"

if ARGV.empty?
  STDERR.puts "Usage: xephyr-run \"<command>\""
  exit 1
end

command_to_run = ARGV[0]

client   = Xephyr::Client.new(command_to_run)
response = client.execute

if response.success?
  puts response.display
else
  STDERR.puts "Error: #{response.error}"
  exit 1
end
