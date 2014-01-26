require 'spec_helper'

describe "Basic examples" do
  include BroSystemTest

  it "can ask about curl for example" do
    result = bro "curl"

    expect(result).to match /[\d+] entries for curl/
  end

  it "tells me when there is no manual for a command" do
    an_unknown_command = "xxx_unknown_command_xxx" 

    result = bleach (bro an_unknown_command)

    expect(result).to match /The #{an_unknown_command} command isn\'t in our database/
  end

  it "you can turn color off" do
    result = bro "curl --no-color" 
    expect(result).to match /[\d+] entries for curl/
  end

  it "defaults to color on" do
    result = bro "curl"
    expect(result).to match /[\d+] entries for curl/
  end
end
