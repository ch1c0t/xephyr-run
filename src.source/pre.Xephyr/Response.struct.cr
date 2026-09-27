include JSON::Serializable

# "SUCCESS" or "ERROR"
property status : String

# Populated only on successful startup or termination queries
property display : String?

# Populated only on failure triggers
property error : String?

def initialize(@status : String, @display : String? = nil, @error : String? = nil)
end

def success? : Bool
  status == "SUCCESS"
end
