# Track display indices across all instances concurrently using an atomic counter
@@display_counter = Atomic(Int32).new(10)

@channel : ::AMQP::Client::Channel
@raw_payload : String
@app_executable : String
@app_args : Array(String)
@resolved_path : String?

def initialize(@message : AMQP::Client::DeliverMessage)
  @channel = Global.amqp_channel
  @raw_payload = @message.body_io.to_s

  @parts = @raw_payload.strip.split(' ')
  @app_executable = @parts.shift? || ""
  @app_args = @parts
end

include Helpers
include X11Stack
include Run
