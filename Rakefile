$:.unshift './lib'

require 'rubygems'
require 'rake'

require 'rake/gempackagetask'
require 'rake/testtask'
require 'rake/rdoctask'

Gem.manage_gems

gem_spec = Gem::Specification.new do |s|
  s.name = 'junebug'
  s.version = '0.0.14'
  s.summary = "Junebug is a minimalist ruby wiki."
  s.description = "Junebug is a minimalist ruby wiki running on Camping."
  s.author = "Tim Myrtle"
  s.email = 'tim.myrtle@gmail.com'
  s.homepage = 'http://www.junebugwiki.com/'
  
  s.require_paths = ['lib']
  s.bindir = 'bin'
  s.executables = ['junebug']
  s.files = FileList['README','LICENSE','CHANGELOG','Rakefile','lib/**/*','deploy/**/*','dump/**/*']
  s.test_files = FileList['test/**/*']

  s.add_dependency('mongrel', '>=0.3.13.4')
  s.add_dependency('camping', '>=1.5')
  s.add_dependency('RedCloth', '>=3.0.4')
  s.add_dependency('daemons')
  s.add_dependency('sqlite3-ruby', '>=1.1.0.1')
  s.add_dependency('activerecord', '>=1.14.4')
end


Rake::GemPackageTask.new(gem_spec) do |pkg|
  pkg.need_zip = false
  pkg.need_tar = false
end


desc "View tidy html from dev server in editor"
task :tidy do
  system("curl http://localhost:3301/#{ENV['PAGE']} | tidy -i -wrap 1000 | #{ENV['VISUAL'] || ENV['EDITOR'] || 'vim' }")
end


desc "Clean up directory"
task :clean => :clobber_package do
  rm 'deploy/junebug.db', :force => true
  rm 'deploy/junebug.log', :force => true
  Dir['deploy/dump/*'].each { |ext| rm ext }
  rm 'test/test.log', :force => true
end


desc 'Test the campground.'
Rake::TestTask.new(:test) do |t|
#  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end







