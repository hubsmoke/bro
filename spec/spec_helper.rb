require 'rspec'

dirname = File.expand_path File.dirname(__FILE__)

Dir.glob(File.join(dirname, "support", "**", "*.rb")).each{|f| require f}
