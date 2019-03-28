
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "fastest_server/version"

Gem::Specification.new do |spec|
  spec.name          = "fastest_server"
  spec.version       = FastestServer::VERSION
  spec.authors       = ["DeathKing"]
  spec.email         = ["deathking0622@gmail.com"]
  spec.license       = "MIT"

  spec.summary       = %q{Find the fastest server via ping.}
  spec.description   = %q{Find the fastest server via ping.}
  spec.homepage      = "https://github.com/DeathKing/fastest_server"

  spec.files         = `git ls-files`.split("\n")
  spec.bindir        = "bin"
  spec.executables   << 'fastest'
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_dependency "clamp", "~> 1.0"
end
