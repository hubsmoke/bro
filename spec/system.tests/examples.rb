require 'spec_helper'

describe "Basic examples" do
  it "can ask about curl for example" do
    result = ColourBlind.strip(BroCli.run "curl")

    expect(result).to match /[\d+] entries for curl/
  end

  it "rejects an unknown command"
  it "you can turn color off"
end

class ColourBlind
  def self.strip(text)
    text.gsub(/\e\[(\d+)m/, '')
  end
end

class BroCli
  class << self
    def run(command)
      `ruby bin/bro #{command}`
    end
  end
end
