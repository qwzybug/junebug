$:.unshift './lib'

require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/contrib/rubyforgepublisher'
require 'fileutils'
require 'hoe'
include FileUtils
require File.join(File.dirname(__FILE__), 'lib', 'junebug', 'version')

AUTHOR            = "Tim Myrtle"  # can also be an array of Authors
EMAIL             = "tim.myrtle@gmail.com"
DESCRIPTION       = "Junebug is a minimalist ruby wiki running on Camping."
GEM_NAME          = "junebug-wiki" # what ppl will type to install your gem
RUBYFORGE_PROJECT = "junebug" # The unix name for your project
HOMEPATH          = "http://www.junebugwiki.com"
RELEASE_TYPES     = %w( gem ) # can use: gem, tar, zip

#NAME = "junebug" # I don't think this is used
REV  = nil # File.read(".svn/entries")[/committed-rev="(d+)"/, 1] rescue nil
VERS = ENV['VERSION'] || (Junebug::VERSION::STRING + (REV ? ".#{REV}" : ""))
CLEAN.include ['**/.*.sw?', '*.gem', '.config', '**/*.db', '**/*.log', 'config.yml', 'deploy/dump/*']
TEST = ["test/**/*_test.rb"]
RDOC_OPTS = ['--quiet', '--title', "junebug documentation",
    "--opname", "index.html", "--line-numbers", "--main", "README", "--inline-source"]

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
hoe = Hoe.new(GEM_NAME, VERS) do |p|
  p.author         = AUTHOR 
  p.description    = DESCRIPTION
  p.email          = EMAIL
  p.summary        = DESCRIPTION
  p.url            = HOMEPATH
  p.rubyforge_name = RUBYFORGE_PROJECT
  p.test_globs     = TEST
  p.clean_globs    = CLEAN
  p.need_tar       = false
  p.changes        = p.paragraphs_of('History.txt', 0..1).join("\n\n")
  
  # == Optional
  #p.changes        - A description of the release's latest changes.
  #p.spec_extras    - A hash of extra values to set in the gemspec.
  p.extra_deps = [
      ['mongrel',      '<=1.1.2'],
      ['camping',      '>=1.5'],
      ['daemons',      '>=1.0.4'],
      ['sqlite3-ruby', '>=1.2'],
      ['activerecord', '<=1.15.6'],
      ['activesupport', '<=1.4.4']
    ]
end

# Disable suprious warnings when running tests
# submitted by Julian Tarkhanov

Hoe::RUBY_FLAGS.replace ENV['RUBY_FLAGS'] || "-I#{%w(lib ext bin test).join(File::PATH_SEPARATOR)}" +
  (Hoe::RUBY_DEBUG ? " #{RUBY_DEBUG}" : '')



