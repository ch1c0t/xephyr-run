class XephyrSession
  private def cleanup
    terminate_process(@app)
    terminate_process(@wm)
    terminate_process(@xephyr)
  end
end
