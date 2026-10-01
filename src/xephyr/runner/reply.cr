module Xephyr
  class Runner
    private def response_queue : String
      queue = @message.properties.reply_to
      raise MissingReplyToError.new if queue.nil? || queue.empty?
      queue
    end

    private def send_reply(response : Xephyr::Response)
      @channel.basic_publish(
        response.to_json,
        exchange: "",
        routing_key: response_queue
      )
    end
  end
end
