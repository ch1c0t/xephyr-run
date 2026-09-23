require "../global"
ch = Global.amqp_channel
worker_queue = ch.queue("xephyr_commands")

puts "LavinMQ Daemon running via Global.amqp_channel."
puts "Awaiting jobs on queue 'xephyr_commands'..."

require "../xephyr_runner"
# Block the fiber loop to continuously parse events as they arrive
worker_queue.subscribe(no_ack: true) do |msg|
  runner = XephyrRunner.new(msg)
  runner.run
end

# Keep the execution thread execution timeline context alive
sleep
