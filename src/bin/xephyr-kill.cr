require "./xephyr-kill/*"

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

unless ARGV.size == 1
  STDERR.puts "Usage: xephyr-kill DISPLAY_TARGET"
  exit 1
end

display_target = ARGV[0]
response = Xephyr::Client.kill(display_target).execute

if response.success?
  puts response.display
else
  STDERR.puts "Error: #{response.error}"
  exit 1
end
