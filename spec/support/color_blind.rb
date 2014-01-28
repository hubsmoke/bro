class ColourBlind
  def self.strip(text)
    text.gsub(/\e\[(\d+)m/, '')
  end
end
