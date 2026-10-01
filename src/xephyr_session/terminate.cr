class XephyrSession
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
end
