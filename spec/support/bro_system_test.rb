module BroSystemTest
  def bro(command)
    BroCli.run command
  end

  def bleach(text)
    ColourBlind.strip text
  end
end
