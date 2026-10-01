module Xephyr
  class Session
    def start
      @xephyr = Process.new(
        "Xephyr", [@display, "-screen", screen_resolution, "-ac"]
      )
      wait_for_x_server

      @wm = Process.new(
        "matchbox-window-manager", ["-use_titlebar", "no"],
        env: {"DISPLAY" => @display}
      )

      start_application
      wait_for_process_start
      raise "Application failed to start" unless @app.not_nil!.exists?
    rescue ex : Exception
      cleanup
      raise ex
    end

    private def start_application
      @app = Process.new(
        "setsid", ["/bin/sh", "-c", @command],
        env: {"DISPLAY" => @display},
        error: @app_stderr_buffer
      )
    end
  end
end
