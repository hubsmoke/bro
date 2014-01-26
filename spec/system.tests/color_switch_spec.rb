require "spec_helper"

describe "The color switch" do
  include BroSystemTest

  let(:any_ansi_escape_sequence) { /\e\[(\d+)m/ }

  it "you can turn color off" do
    result = bro "--no-color" 
    expect(result).to_not match any_ansi_escape_sequence 
  end

  it "defaults to color on" do
    result = bro ""
    expect(result).to match any_ansi_escape_sequence
  end
end
