version = File.read(File.expand_path("NMSPEC_VERSION", __dir__)).strip

Gem::Specification.new do |s|
  s.name        = 'nmspec'
  s.version     = version
  s.summary     = "nmspec is a network message specification language for network peers"
  s.description = "nmspec makes it easier to describe binary messages between two network peers via a config file, generate their network code in a number of languages, and keep their code in sync"
  s.authors     = ["Jeff Lunt"]
  s.email       = 'jefflunt@gmail.com'
  s.files       = ["lib/nmspec.rb"]
  s.homepage    =
    'https://nmspec.com'
  s.license       = 'MIT'
end
