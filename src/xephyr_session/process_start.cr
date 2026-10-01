class XephyrSession
  private def wait_for_process_start
    100.times do
      return if @app.not_nil!.exists?
      sleep 10.milliseconds
    end
  end
end
