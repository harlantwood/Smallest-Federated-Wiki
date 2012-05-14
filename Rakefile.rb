require 'rspec/core/rake_task'

desc "Run all RSpec tests"
RSpec::Core::RakeTask.new(:spec)

task :default => :spec

Dir[File.expand_path("stores/**/*.rake", File.dirname(__FILE__))].each { |rakefile| import rakefile }
