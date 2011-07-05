# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "spectral_summing"
  gem.homepage = "http://github.com/ryanmt/spectral_summing"
  gem.license = "MIT"
  gem.summary = %Q{This is a gem that should enable combination of MS/MS spectra into a combined spectrum representative of the total of all of those scans.  Currently, this can be output as an MGF file.}
  gem.description = %Q{This is not quite built to the level I expect it will someday achieve, so please let me know if you have a suggestion.  The current interface for options requires you to change the source code.  I'll work on that, long-term, but it works right now.  CLI is given if you call the program without any arguments or the wrong number of arguments.}
  gem.email = "ryanmt@byu.net"
  gem.authors = ["Ryan Taylor"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.verbose = true
end

require 'rcov/rcovtask'
Rcov::RcovTask.new do |spec|
  spec.libs << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.verbose = true
  spec.rcov_opts << '--exclude "gems/*"'
end

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "spectral_summing #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
