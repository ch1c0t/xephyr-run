module Xephyr
  class Session
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
  end
end
