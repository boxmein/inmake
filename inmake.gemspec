$:.push File.expand_path("../lib", __FILE__)
require "mygem/version"

Gem::Specification.new do |s|
  s.name = 'inmake'
  s.version = Inmake::Version
  s.date = '2015-07-06'
  s.summary = 'Inline Build Commands'
  s.description = 'Inline build command runner for any kind of projects.'
  s.authors = ['boxmein']
  s.email = 'boxmein@boxmein.net'
  s.files = ['lib/inmake.rb', 'lib/inmake/config.rb', 'lib/inmake/runner.rb']
  s.executables = ['inmake']
  s.require_paths = ['lib']
  s.homepage = 'https://github.com/boxmein/inmake'
  s.license = 'MIT'
end