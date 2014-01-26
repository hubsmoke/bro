require 'spec_helper'

module BroDsl
  def bro(command)
    BroCli.run command
  end
end

describe "Basic examples" do
  include BroDsl

  it "can ask about curl for example" do
    result = bro "curl" 

    expect(result).to match /[\d+] entries for curl/
  end

  it "tells me when there is no manual for a command" do
    an_unknown_command = "xxx_unknown_command_xxx" 

    result = bro an_unknown_command 

    expect(result).to match /The #{an_unknown_command} command isn't in our database/
  end

  it "you can turn color off"
end

class BroCli
  class << self
    def run(command)
      ColourBlind.strip `ruby bin/bro #{command}`
    end
  end
end

class ColourBlind
  def self.strip(text)
    text.gsub(/\e\[(\d+)m/, '')
  end
end
