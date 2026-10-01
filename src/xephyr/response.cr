module Xephyr
  struct Response
    include JSON::Serializable
    SUCCESS = "SUCCESS"
    ERROR = "ERROR"
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
end
