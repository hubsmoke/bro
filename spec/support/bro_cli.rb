class BroCli
  class << self
    def run(command)
      exe = File.join ".", "spec", "system.tests", "bin", "bro"
      
      `#{exe} #{command}`
    end
  end
end
