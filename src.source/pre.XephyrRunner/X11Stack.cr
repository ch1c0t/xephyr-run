private def x11_stack(display : String)
  begin
    app_stderr_buffer = IO::Memory.new

    xephyr = Process.new("Xephyr", [display, "-screen", screen_resolution, "-ac"])
    sleep 50.milliseconds
    wm = Process.new("matchbox-window-manager", ["-use_titlebar", "no"], env: {"DISPLAY" => display})

    app = Process.new(
      command: resolved_path,
      args: @app_args,
      env: {"DISPLAY" => display},
      error: app_stderr_buffer
    )
    sleep 50.milliseconds

    if app.exists?
      puts "[-]·Screen·#{display}·Operational.·Running·PID·#{app.pid}"
      send_reply(display)

      exit_status = app.wait
      if exit_status.success?
        puts "[x] Program inside #{display} closed. Cleaning up Xephyr process..."
      else
        log_application_failure(
          @app_executable,
          @raw_payload,
          display,
          exit_status.exit_code,
          app_stderr_buffer.to_s
        )
      end
    else
      send_reply("ERROR: Application crashed immediately on startup")
    end

    wm.terminate if wm.exists?
    xephyr.terminate if xephyr.exists?
  rescue ex : Exception
    send_reply("ERROR: Server runtime failure")
    STDERR.puts "System execution failure for #{display} inside target '#{@raw_payload}': #{ex.message}"
  end
end
