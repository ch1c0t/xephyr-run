# Helper function to dynamically discover the current screen resolution via xrandr
def screen_resolution : String
  stdout_buffer = IO::Memory.new
  status = Process.run("xrandr", args: ["--current"], output: stdout_buffer)

  if status.success?
    output_string = stdout_buffer.to_s
    if match = output_string.match(/\b(\d+)x(\d+)\b/)
      return match[0]
    end
  end

  # Safe hardcoded fallback if xrandr is missing or fails to parse
  "1024x768"
end
