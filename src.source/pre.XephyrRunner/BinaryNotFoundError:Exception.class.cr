def initialize(app_executable : String)
  super("Program '#{app_executable}' is not installed or not available in PATH.")
end
