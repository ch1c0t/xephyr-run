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

    # Start the command in its own process group so KILL can terminate the
    # command and any children it created.
    @app = Process.new(
      "setsid",
      ["/bin/sh", "-c", @command],
      env: {"DISPLAY" => @display},
      error: @app_stderr_buffer
    )

    wait_for_process_start

    unless @app.not_nil!.exists?
      raise "Application failed to start"
    end
  rescue ex : Exception
    cleanup
    raise ex
  end

  def wait
    exit_status = @app.not_nil!.wait

    unless exit_status.success?
      log_application_failure(
        @command,
        @display,
        exit_status.exit_code?,
        @app_stderr_buffer.to_s
      )
    end
  ensure
    cleanup
  end

  def terminate
    terminate_application
    terminate_process(@wm)
    terminate_process(@xephyr)
  end

  private def terminate_application
    return unless @app && @app.not_nil!.exists?

    Process.signal(Signal::TERM, -@app.not_nil!.pid)
  rescue ex : Exception
    @app.not_nil!.terminate
  end

  private def terminate_process(process : Process?)
    return unless process && process.not_nil!.exists?

    process.not_nil!.terminate
  end

  private def cleanup
    terminate_process(@wm)
    terminate_process(@xephyr)
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
