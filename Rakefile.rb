require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:all)

task :default => :all
