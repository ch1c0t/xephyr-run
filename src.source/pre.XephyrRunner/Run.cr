# Spawns Xephyr and the nested application inside a separate concurrent context
def run
  display_id = @@display_counter.add(1)
  display_string = ":#{display_id}"
  puts "\n[+] Validated: #{resolved_path} -> Spawning screen #{display_string} [Size: #{screen_resolution}]"

  spawn x11_stack(display_string)
end
