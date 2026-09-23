def response_queue : String
  queue = @message.properties.reply_to
  if queue.nil? || queue.empty?
    raise MissingReplyToError.new
  end
  queue
end

def resolved_path : String
  found_path = Process.find_executable(@app_executable)
  if found_path.nil?
    raise BinaryNotFoundError.new(@app_executable)
  end

  found_path
end

private def send_reply(payload_text : String)
  @channel.basic_publish(payload_text, exchange: "", routing_key: response_queue)
end
