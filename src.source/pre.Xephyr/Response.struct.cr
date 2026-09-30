include JSON::Serializable

# A response sent from xephyrd back to an xephyr client.
struct Response
  SUCCESS = "SUCCESS"
  ERROR   = "ERROR"

  property status : String
  property display : String?
  property error : String?

  def initialize(
    @status : String,
    @display : String? = nil,
    @error : String? = nil
  )
  end

  def success? : Bool
    status == SUCCESS
  end
end
