# Helper function to write failure logs to both the console and a physical log file
def log_application_failure(app_name : String, display_string : String, exit_code : Int32, error_logs : String)
  # 1. Build destination path: ~/.local/state/xephyrd/
  state_dir = Path.home.join(".local", "state", "xephyrd")
  Dir.mkdir_p(state_dir) # Creates the directory path safely if it is missing

  # 2. Generate a unique filename using timestamp and display id
  timestamp = Time.local.to_s("%Y%m%d_%H%M%S")
  safe_display = display_string.gsub(':', "")
  log_filename = "#{timestamp}_#{app_name}_#{safe_display}.log"
  log_filepath = state_dir.join(log_filename)

  # 3. Format the complete diagnostic report payload
  report = String.build do |io|
    io << "CRASH REPORT\n"
    io << "Time:          #{Time.local}\n"
    io << "Application:   #{app_name}\n"
    io << "Display:       #{display_string}\n"
    io << "Exit Code:     #{exit_code}\n"
    io << "Captured Logs:\n"
    io << (error_logs.empty? ? "[No stderr logs emitted]" : error_logs)
  end

  # 4. Write data out to the physical file system path
  File.write(log_filepath, report)

  # 5. Print matching error info out to standard error stream (STDERR)
  STDERR.puts "\n[!] CRASH DETECTED: Application '#{app_name}' failed on #{display_string} (Exit Code: #{exit_code})."
  STDERR.puts "    Log saved to: #{log_filepath}"
  if !error_logs.strip.empty?
    STDERR.puts "    Captured Output Logs:\n--- Start App Logs ---\n#{error_logs.strip}\n--- End App Logs ---"
  end
end
