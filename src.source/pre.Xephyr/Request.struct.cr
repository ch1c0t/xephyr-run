include JSON::Serializable

# A request sent from an xephyr client to xephyrd.
#
# START carries the command exactly as supplied to xephyr-run.
# KILL carries the display name that identifies an existing session.
struct Request
  START = "START"
  KILL  = "KILL"

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
