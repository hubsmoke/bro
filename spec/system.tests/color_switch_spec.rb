require "spec_helper"

describe "The color switch" do
  include BroSystemTest

  let(:any_ansi_escape_sequence) { /\e\[(\d+)m/ }

  it "you can turn color off" do
    result = bro "--no-color" 
    expect(result).to_not match any_ansi_escape_sequence 
  end

  it "you can turn color on" do
    result = bro "--with-color"
    expect(result).to match any_ansi_escape_sequence
  end

  it "caches the switch in case you don't want color"

  it "defaults to color output"
end
