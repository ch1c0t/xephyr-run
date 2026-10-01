class XephyrRunner
  private def kill_session(display : String)
    session = @@sessions.delete(display)
    unless session
      send_reply(Xephyr::Response.new(
        status: Xephyr::Response::ERROR,
        error: "No running Xephyr session for #{display}"
      ))
      return
    end

    session.terminate
    send_reply(Xephyr::Response.new(
      status: Xephyr::Response::SUCCESS, display: display
    ))
  end

  private def start_session(command : String)
    display = ":#{@@display_counter.add(1)}"
    session = XephyrSession.new(display, command)
    session.start
    @@sessions[display] = session

    spawn do
      session.wait
      @@sessions.delete(display)
    end

    send_reply(Xephyr::Response.new(
      status: Xephyr::Response::SUCCESS, display: display
    ))
  end
end
