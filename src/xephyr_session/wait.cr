class XephyrSession
  def wait
    exit_status = @app.not_nil!.wait
    if !exit_status.success? && exit_status.normal_exit?
      log_application_failure(
        @command, @display, exit_status.exit_code,
        @app_stderr_buffer.to_s
      )
    end
  ensure
    cleanup
  end
end
