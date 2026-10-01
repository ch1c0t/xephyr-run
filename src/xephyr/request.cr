module Xephyr
  struct Request
    include JSON::Serializable

    START = "START"
    KILL = "KILL"

    property action : String
    property command : String?
    property display : String?

    def initialize(
      @action : String,
      @command : String? = nil,
      @display : String? = nil
    )
    end

    def valid? : Bool
      case action
      when START
        !command.nil? && !command.not_nil!.empty?
      when KILL
        !display.nil? && !display.not_nil!.empty?
      else
        false
      end
    end
  end
end
