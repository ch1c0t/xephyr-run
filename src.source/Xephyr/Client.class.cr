def initialize(@command_string : String)
  @channel = Global.amqp_channel
  @response_bridge = Channel(String).new

  # Generate the unique PID-isolated queue names matching your naming pattern
  @queue_name = "#{Process.pid}.xephyr_commands.out"
end

def execute : Xephyr::Response
  # 1. Setup the transient, auto-deleting response queue
  response_queue = @channel.queue(@queue_name, auto_delete: true, exclusive: true)

  # 2. Wire up the listener fiber to pass network messages to our channel bridge
  response_queue.subscribe(no_ack: true) do |msg|
    @response_bridge.send(msg.body_io.to_s)
  end

  # 3. Serialize our protocol request packet
  request_payload = Xephyr::Request.new(
    action: "START",
    command: @command_string
  ).to_json

  # 4. Transmit over the AMQP bus exchange line
  @channel.basic_publish(
    payload: request_payload,
    exchange: "",
    routing_key: "xephyr_commands",
    props: AMQP::Client::Properties.new(reply_to: @queue_name)
  )

  # 5. Block synchronously until the response object arrives, then parse it
  Xephyr::Response.from_json(@response_bridge.receive)
end
