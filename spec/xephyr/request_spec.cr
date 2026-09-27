require "../spec_helper"

describe Xephyr::Request do
  it "round-trips a START request" do
    request = Xephyr::Request.new(
      action: "START",
      command: "xterm --hold"
    )

    decoded = Xephyr::Request.from_json(request.to_json)

    decoded.action.should eq "START"
    decoded.command.should eq "xterm --hold"
    decoded.display.should be_nil
    decoded.valid?.should be_true
  end

  it "round-trips a KILL request" do
    request = Xephyr::Request.new(
      action: "KILL",
      display: ":12"
    )

    decoded = Xephyr::Request.from_json(request.to_json)

    decoded.action.should eq "KILL"
    decoded.display.should eq ":12"
    decoded.command.should be_nil
    decoded.valid?.should be_true
  end

  it "rejects an unknown action" do
    Xephyr::Request.new(action: "RESTART").valid?.should be_false
  end

  it "rejects START without a command" do
    Xephyr::Request.new(action: "START").valid?.should be_false
  end

  it "rejects KILL without a display" do
    Xephyr::Request.new(action: "KILL").valid?.should be_false
  end

  it "rejects an empty command" do
    Xephyr::Request.new(action: "START", command: "").valid?.should be_false
  end
end
