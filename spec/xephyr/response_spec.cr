require "../spec_helper"

describe Xephyr::Response do
  it "round-trips a successful response" do
    response = Xephyr::Response.new("SUCCESS", display: ":12")

    decoded = Xephyr::Response.from_json(response.to_json)

    decoded.status.should eq "SUCCESS"
    decoded.display.should eq ":12"
    decoded.error.should be_nil
    decoded.success?.should be_true
  end

  it "round-trips an error response" do
    response = Xephyr::Response.new("ERROR", error: "Unknown action: RESTART")

    decoded = Xephyr::Response.from_json(response.to_json)

    decoded.status.should eq "ERROR"
    decoded.display.should be_nil
    decoded.error.should eq "Unknown action: RESTART"
    decoded.success?.should be_false
  end
end
