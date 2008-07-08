require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rcov/rcovtask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the fake_record plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate test info via rcov for the plugin.'
Rcov::RcovTask.new :rcov do |t|
  t.test_files = Dir.glob("test/**/*_test.rb")
  t.verbose = true
  t.rcov_opts << [ '--exclude', File.expand_path(File.dirname(__FILE__)+'/../../..') ]
end

desc 'Generate documentation for the fake_record plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'FakeRecord'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
