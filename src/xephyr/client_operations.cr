module Xephyr
  class Client
    def self.start(command : String)
      new(
        Xephyr::Request.new(
          action: Xephyr::Request::START,
          command: command
        )
      )
    end

    def self.kill(display : String)
      new(
        Xephyr::Request.new(
          action: Xephyr::Request::KILL,
          display: display
        )
      )
    end
  end
end
