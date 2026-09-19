# Track display indices across all instances concurrently using an atomic counter
@@display_counter = Atomic(Int32).new(10)

def initialize(@raw_payload : String)
  @parts = @raw_payload.strip.split(' ')
  @app_executable = @parts.shift? || ""
  @app_args = @parts
  @resolved_path = nil : String?
end

# Validates that the payload is well-formed and the executable exists
def valid? : Bool
  return false if @app_executable.empty?
  
  @resolved_path = Process.find_executable(@app_executable)
  if @resolved_path.nil?
    STDERR.puts "\n[!] Rejected: Program '#{@app_executable}' is not installed or not in PATH."
    return false
  end
  
  true
end

include Run
