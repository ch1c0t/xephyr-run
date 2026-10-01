class XephyrSession
  getter display : String

  @xephyr : Process?
  @wm : Process?
  @app : Process?
  @app_stderr_buffer : IO::Memory

  def initialize(@display : String, @command : String)
    @xephyr = nil
    @wm = nil
    @app = nil
    @app_stderr_buffer = IO::Memory.new
  end

  def start
    @xephyr = Process.new(
      "Xephyr",
      [@display, "-screen", screen_resolution, "-ac"]
    )

    wait_for_x_server

    @wm = Process.new(
      "matchbox-window-manager",
      ["-use_titlebar", "no"],
      env: {"DISPLAY" => @display}
    )

    @app = Process.new(
      "/bin/sh",
      ["-c", @command],
      env: {"DISPLAY" => @display},
      error: @app_stderr_buffer
    )

    wait_for_process_start

    unless @app.not_nil!.exists?
      raise "Application failed to start"
    end
  rescue
    cleanup
    raise
  end

  def wait
    exit_status = @app.not_nil!.wait

    unless exit_status.success?
      log_application_failure(
        @command,
        @display,
        exit_status.exit_code,
        @app_stderr_buffer.to_s
      )
    end
  ensure
    cleanup
  end

  def terminate
    @app.try &.terminate if @app && @app.not_nil!.exists?
    @wm.try &.terminate if @wm && @wm.not_nil!.exists?
    @xephyr.try &.terminate if @xephyr && @xephyr.not_nil!.exists?
  end

  private def cleanup
    terminate
  end

  private def wait_for_x_server
    100.times do
      return if Process.run(
        "xdpyinfo",
        args: ["-display", @display],
        output: Process::Redirect::Close,
        error: Process::Redirect::Close
      ).success?

      sleep 50.milliseconds
    end

    raise "Xephyr did not become ready on #{@display}"
  end

  private def wait_for_process_start
    100.times do
      return if @app.not_nil!.exists?
      sleep 10.milliseconds
    end
  end
end
