include JSON::Serializable

# "SUCCESS" or "ERROR"
property status : String

# Populated when a session has a display.
property display : String?

# Populated when the request cannot be completed.
property error : String?

def initialize(@status : String, @display : String? = nil, @error : String? = nil)
end

def success? : Bool
  status == "SUCCESS"
end
