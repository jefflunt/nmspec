require_relative './lib/nmspec/version.rb'

Gem::Specification.new do |s|
  s.name        = 'nmspec'
  s.version     = NMSPEC_GEM_VERSION
  s.summary     = "nmspec is a network message specification language for network peers"
  s.description = "nmspec makes it easier to describe binary messages between two network peers via a config file, generate their network code in a number of languages, and keep their code in sync"
  s.authors     = ["Jeff Lunt"]
  s.email       = 'jefflunt@gmail.com'
  s.files       = ["lib/nmspec.rb"]
  s.homepage    = 'http://nmspec.com'
  s.license     = 'MIT'
  s.metadata    = { "source_code_uri" => "https://github.com/jefflunt/nmspec" }
end
