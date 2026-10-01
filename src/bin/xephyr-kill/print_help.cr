HELP_MESSAGE = <<-S
xephyr-kill is to terminate Xephyr instances started with xephyr-run.

xephyr-kill DISPLAY_TARGET

For example:

    xephyr-kill ":10"

It terminates all processes associated with DISPLAY_TARGET(inside of the
xephyrd daemon).
S

def print_help
  puts HELP_MESSAGE
end
