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
end
