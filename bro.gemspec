$:.push File.expand_path("../lib", __FILE__)
require 'bro/version'

Gem::Specification.new do |s|
  s.name        = 'bropages'
  s.version     = Bro::VERSION
  s.date        = '2013-12-21'
  s.summary     = "Bro"
  s.description = "Highly readable supplement to man pages. Shows simple, concise examples for unix commands."
  s.authors     = ["bropages.org"]
  s.email       = 'info@bropages.org'
  s.files       = [ "lib/bro.rb", 
                    "lib/bro/state.rb",
                    "lib/bro/bro_state.rb",
                    "lib/bro/string_hacks.rb",
                    "lib/bro/version.rb"]
  s.homepage    = 'http://bropages.org'
  s.executables << 'bro'
  s.add_runtime_dependency 'json_pure', '1.8.1'
  s.add_runtime_dependency 'commander', '4.1.5'
  s.add_runtime_dependency 'rest-client'
  s.add_runtime_dependency 'smart_colored'
  s.add_runtime_dependency 'highline', '1.6.20'
  s.add_runtime_dependency 'mime-types', '1.19'
end
