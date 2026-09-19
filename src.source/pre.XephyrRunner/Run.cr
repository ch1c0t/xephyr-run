# Spawns Xephyr and the nested application inside a separate concurrent context
def run
  # Ensure verification passed before spinning up infrastructure
  path = @resolved_path
  return if path.nil?

  display_id = @@display_counter.add(1)
  display_string = ":#{display_id}"
  puts "\n[+] Validated: #{path} -> Spawning screen #{display_string} [Size: #{screen_resolution}]"

  spawn do
    app_stderr_buffer = IO::Memory.new

    begin
      xephyr_process = Process.new(
        command: "Xephyr", 
        args: [display_string, "-screen", screen_resolution, "-ac"]
      )

      sleep 100.milliseconds

      wm_process = Process.new(
        command: "matchbox-window-manager",
        args: ["-use_titlebar", "no"],
        env: {"DISPLAY" => display_string}
      )

      app_process = Process.new(
        command: path,
        args: @app_args,
        env: {"DISPLAY" => display_string},
        error: app_stderr_buffer
      )

      puts "[-] Screen #{display_string} Operational. Running PID #{app_process.pid}"

      exit_status = app_process.wait
      if exit_status.success?
        puts "[x] Program inside #{display_string} closed. Cleaning up Xephyr process..."
      else
        log_application_failure(
          @app_executable,
          @raw_payload,
          display_string,
          exit_status.exit_code,
          app_stderr_buffer.to_s
        )
      end

      wm_process.terminate if wm_process.exists?
      xephyr_process.terminate if xephyr_process.exists?
    rescue ex : Exception
      STDERR.puts "System execution failure inside target '#{@raw_payload}': #{ex.message}"
    end
  end
end
