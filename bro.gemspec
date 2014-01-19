Gem::Specification.new do |s|
  s.name        = 'bropages'
  s.version     = '0.0.4'
  s.date        = '2013-12-21'
  s.summary     = "Bro"
  s.description = "Highly readable supplement to man pages. Shows simple, concise examples for unix commands."
  s.authors     = ["bropages.org"]
  s.email       = 'info@bropages.org'
  s.files       = ["lib/bro.rb"]
  s.homepage    = 'http://bropages.org'
  s.executables << 'bro'
  s.add_runtime_dependency 'json_pure'
  s.add_runtime_dependency 'commander'
  s.add_runtime_dependency 'rest-client'
  s.add_runtime_dependency 'smart_colored'
  s.add_runtime_dependency 'highline'
end